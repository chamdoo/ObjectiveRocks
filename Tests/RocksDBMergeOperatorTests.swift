//
//  RocksDBMergeOperatorTests.swift
//  ObjectiveRocks
//
//  Created by Iska on 14/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

import XCTest
import ObjectiveRocks

class RocksDBMergeOperatorTests : RocksDBTests {

	func testSwift_AssociativeMergeOperator() {
		let mergeOp = RocksDBMergeOperator(name: "operator") { (key, existing, value) -> AnyObject in
			var prev: UInt64 = 0
			if let existing = existing {
				existing.getBytes(&prev, length: sizeof(UInt64))
			}
			var plus: UInt64 = 0
			value.getBytes(&plus, length: sizeof(UInt64))

			var result: UInt64 = prev + plus
			return NSData(bytes: &result, length: sizeof(UInt64))
		}

		rocks = RocksDB.databaseAtPath(self.path, andDBOptions: { (options) -> Void in
			options.createIfMissing = true
			options.mergeOperator = mergeOp
		})

		var value: UInt64 = 1
		try! rocks.mergeData(NumData(value), forKey: Data("key 1"))

		value = 5
		try! rocks.mergeData(NumData(value), forKey: Data("key 1"))

		let res: UInt64 = Val(try! rocks.dataForKey(Data("key 1")))

		XCTAssertTrue(res == 6);
	}

	func testSwift_AssociativeMergeOperator_NumberAdd_Encoded() {
		let mergeOp = RocksDBMergeOperator(name: "operator") { (key, existing, value) -> AnyObject in
			var val = value.floatValue
			if let existing = existing {
				val = val + existing.floatValue
			}
			let result: NSNumber = NSNumber(float: val)
			return result
		}

		rocks = RocksDB.databaseAtPath(self.path, andDBOptions: { (options) -> Void in
			options.createIfMissing = true
			options.mergeOperator = mergeOp
			options.keyType = .NSString

			options.valueEncoder = {
				(key, value) -> NSData in
				let val = value.floatValue
				let data = NumData(val)
				return data
			}

			options.valueDecoder = {
				(key, data) -> NSNumber in
				if (data == nil) {
					return Optional.None!
				}

				let value: Float = Val(data)
				return NSNumber(float: value)
			}
		})

		try! rocks.mergeObject(NSNumber(float: 100.541), forKey: "key 1")
		try! rocks.mergeObject(NSNumber(float: 200.125), forKey: "key 1")

		let result: Float = try! rocks.objectForKey("key 1").floatValue
		XCTAssertEqualWithAccuracy(result, Float(300.666), accuracy: Float(0.0001))
	}

	func testSwift_AssociativeMergeOperator_DictionaryPut_Encoded() {
		let mergeOp = RocksDBMergeOperator(name: "operator") { (key, existing, value) -> AnyObject in
			guard let existing = existing else {
				return value
			}

			existing.addEntriesFromDictionary(value as! [NSObject : AnyObject])
			return existing
		}

		rocks = RocksDB.databaseAtPath(self.path, andDBOptions: { (options) -> Void in
			options.createIfMissing = true
			options.mergeOperator = mergeOp
			options.keyType = .NSString
			options.valueType = .NSJSONSerializable
		})

		try! rocks.setObject(["key 1": "value 1"], forKey: "dict key")
		try! rocks.mergeObject(["key 1": "value 1 new"], forKey: "dict key")
		try! rocks.mergeObject(["key 2": "value 2"], forKey: "dict key")
		try! rocks.mergeObject(["key 3": "value 3"], forKey: "dict key")
		try! rocks.mergeObject(["key 4": "value 4"], forKey: "dict key")
		try! rocks.mergeObject(["key 5": "value 5"], forKey: "dict key")

		let expected: NSDictionary = ["key 1" : "value 1 new",
			"key 2" : "value 2",
			"key 3" : "value 3",
			"key 4" : "value 4",
			"key 5" : "value 5"]

		XCTAssertEqual(try! rocks.objectForKey("dict key") as! NSDictionary, expected)
	}

	func testSwift_MergeOperator_DictionaryUpdate_Encoded() {
		let mergeOp = RocksDBMergeOperator(name: "operator", partialMergeBlock:
			{
				(key, leftOperand, rightOperand) -> String! in
				let left: NSString = leftOperand.componentsSeparatedByString(":")[0]
				let right: NSString = rightOperand.componentsSeparatedByString(":")[0]
				if left.isEqualToString(right as String) {
					return rightOperand
				}
				return Optional.None!

			},
			fullMergeBlock: {
				(key, existing, operands) -> NSMutableDictionary! in

				let dict: NSMutableDictionary = existing as! NSMutableDictionary
				for op in operands as NSArray {
					let comp: NSArray = op.componentsSeparatedByString(":")
					let action: NSString = comp[1] as! NSString
					if action.isEqualToString("DELETE") {
						dict.removeObjectForKey(comp[0])
					} else {
						dict.setObject(comp[2], forKey: comp[0] as! NSString)
					}
				}
				return existing as! NSMutableDictionary
			})

		rocks = RocksDB.databaseAtPath(self.path, andDBOptions: { (options) -> Void in
			options.createIfMissing = true
			options.mergeOperator = mergeOp
			options.keyType = .NSString
			options.valueType = .NSJSONSerializable
		})

		let object = ["key 1" : "value 1",
			"key 2" : "value 2",
			"key 3" : "value 3"]

		try! rocks.setObject(object, forKey: "dict key")

		try! rocks.mergeOperation("key 1:UPDATE:value X", forKey: "dict key")
		try! rocks.mergeOperation("key 4:INSERT:value 4", forKey: "dict key")
		try! rocks.mergeOperation("key 2:DELETE", forKey: "dict key")
		try! rocks.mergeOperation("key 1:UPDATE:value 1 new", forKey: "dict key")

		let expected = ["key 1" : "value 1 new",
			"key 3" : "value 3",
			"key 4" : "value 4"];

		XCTAssertEqual(try! rocks.objectForKey("dict key") as! NSDictionary, expected)
	}
}

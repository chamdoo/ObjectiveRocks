//
//  RocksDBTests.m
//  ObjectiveRocks
//
//  Created by Iska on 15/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBTests.h"

@interface RocksDBBasicTests : RocksDBTests

@end

@implementation RocksDBBasicTests

- (void)testDB_Open_ErrorIfExists
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];
	[_rocks close];

	RocksDB *db = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.errorIfExists = YES;
	}];

	XCTAssertNil(db);
}

- (void)testDB_CRUD
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];
	[_rocks setDefaultReadOptions:^(RocksDBReadOptions *readOptions) {
		readOptions.fillCache = YES;
		readOptions.verifyChecksums = YES;
	} andWriteOptions:^(RocksDBWriteOptions *writeOptions) {
		writeOptions.syncWrites = YES;
	}];


	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];

	XCTAssertEqualObjects([_rocks dataForKey:Data(@"key 1") error:nil], Data(@"value 1"));
	XCTAssertEqualObjects([_rocks dataForKey:Data(@"key 2") error:nil], Data(@"value 2"));
	XCTAssertEqualObjects([_rocks dataForKey:Data(@"key 3") error:nil], Data(@"value 3"));

	[_rocks deleteDataForKey:Data(@"key 2") error:nil];
	XCTAssertNil([_rocks dataForKey:Data(@"key 2") error:nil]);

	NSError *error = nil;
	BOOL ok = [_rocks deleteDataForKey:Data(@"key 2") error:&error];
	XCTAssertTrue(ok);
	XCTAssertNil(error);
}

- (void)testDB_CRUD_Encoded
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
		options.keyType = RocksDBTypeNSString;
		options.valueType = RocksDBTypeNSString;
	}];
	[_rocks setDefaultReadOptions:^(RocksDBReadOptions *readOptions) {
		readOptions.fillCache = YES;
		readOptions.verifyChecksums = YES;
	} andWriteOptions:^(RocksDBWriteOptions *writeOptions) {
		writeOptions.syncWrites = YES;
	}];


	[_rocks setObject:@"value 1" forKey:@"key 1" error:nil];
	[_rocks setObject:@"value 2" forKey:@"key 2" error:nil];
	[_rocks setObject:@"value 3" forKey:@"key 3" error:nil];

	XCTAssertEqualObjects([_rocks objectForKey:@"key 1" error:nil], @"value 1");
	XCTAssertEqualObjects([_rocks objectForKey:@"key 2" error:nil], @"value 2");
	XCTAssertEqualObjects([_rocks objectForKey:@"key 3" error:nil], @"value 3");

	[_rocks deleteObjectForKey:@"key 2" error:nil];
	XCTAssertNil([_rocks objectForKey:@"key 2" error:nil]);

	NSError *error = nil;
	BOOL ok = [_rocks deleteObjectForKey:@"key 2" error:&error];
	XCTAssertTrue(ok);
	XCTAssertNil(error);
}

@end

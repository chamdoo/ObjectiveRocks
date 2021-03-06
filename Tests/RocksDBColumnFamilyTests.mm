//
//  RocksDBColumnFamilyTests.m
//  ObjectiveRocks
//
//  Created by Iska on 29/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDBTests.h"

@interface RocksDBColumnFamilyTests : RocksDBTests

@end

@implementation RocksDBColumnFamilyTests

- (void)testColumnFamilies_List
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];
	[_rocks close];

	NSArray *names = [RocksDB listColumnFamiliesInDatabaseAtPath:_path];

	XCTAssertTrue(names.count == 1);
	XCTAssertEqualObjects(names[0], @"default");
}

- (void)testColumnFamilies_Create
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBColumnFamily *columnFamily = [_rocks createColumnFamilyWithName:@"new_cf" andOptions:nil];

	[columnFamily close];
	[_rocks close];

	NSArray *names = [RocksDB listColumnFamiliesInDatabaseAtPath:_path];

	XCTAssertTrue(names.count == 2);
	XCTAssertEqualObjects(names[0], @"default");
	XCTAssertEqualObjects(names[1], @"new_cf");
}

- (void)testColumnFamilies_Drop
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBColumnFamily *columnFamily = [_rocks createColumnFamilyWithName:@"new_cf" andOptions:nil];

	[columnFamily drop];
	[columnFamily close];
	[_rocks close];

	NSArray *names = [RocksDB listColumnFamiliesInDatabaseAtPath:_path];

	XCTAssertTrue(names.count == 1);
	XCTAssertEqualObjects(names[0], @"default");
}

- (void)testColumnFamilies_Open
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorStringCompareAscending];
	}];

	RocksDBColumnFamily *columnFamily = [_rocks createColumnFamilyWithName:@"new_cf" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorBytewiseDescending];
	}];

	[columnFamily close];
	[_rocks close];

	NSArray *names = [RocksDB listColumnFamiliesInDatabaseAtPath:_path];

	XCTAssertTrue(names.count == 2);
	XCTAssertEqualObjects(names[0], @"default");
	XCTAssertEqualObjects(names[1], @"new_cf");

	RocksDBColumnFamilyDescriptor *descriptor = [RocksDBColumnFamilyDescriptor new];
	[descriptor addColumnFamilyWithName:@"default" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorStringCompareAscending];
	}];
	[descriptor addColumnFamilyWithName:@"new_cf" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorBytewiseDescending];
	}];

	_rocks = [RocksDB databaseAtPath:_path columnFamilies:descriptor andDatabaseOptions:^(RocksDBDatabaseOptions *options) {
		options.createIfMissing = YES;
	}];

	XCTAssertNotNil(_rocks);

	XCTAssertTrue(_rocks.columnFamilies.count == 2);

	RocksDBColumnFamily *defaultColumnFamily = _rocks.columnFamilies[0];
	RocksDBColumnFamily *newColumnFamily = _rocks.columnFamilies[1];

	XCTAssertNotNil(defaultColumnFamily);
	XCTAssertNotNil(newColumnFamily);

	[defaultColumnFamily close];
	[newColumnFamily close];
}

- (void)testColumnFamilies_Open_ComparatorMismatch
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorStringCompareAscending];
	}];

	RocksDBColumnFamily *columnFamily = [_rocks createColumnFamilyWithName:@"new_cf" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorBytewiseDescending];
	}];

	[columnFamily close];
	[_rocks close];

	NSArray *names = [RocksDB listColumnFamiliesInDatabaseAtPath:_path];

	XCTAssertTrue(names.count == 2);
	XCTAssertEqualObjects(names[0], @"default");
	XCTAssertEqualObjects(names[1], @"new_cf");

	RocksDBColumnFamilyDescriptor *descriptor = [RocksDBColumnFamilyDescriptor new];
	[descriptor addColumnFamilyWithName:@"default" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorStringCompareAscending];
	}];
	[descriptor addColumnFamilyWithName:@"new_cf" andOptions:^(RocksDBColumnFamilyOptions *options) {
		options.comparator = [RocksDBComparator comaparatorWithType:RocksDBComparatorStringCompareAscending];
	}];

	_rocks = [RocksDB databaseAtPath:_path columnFamilies:descriptor andDatabaseOptions:^(RocksDBDatabaseOptions *options) {
		options.createIfMissing = YES;
	}];

	XCTAssertNil(_rocks);
}

- (void)testColumnFamilies_CRUD
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	[_rocks setData:Data(@"df_value") forKey:Data(@"df_key1") error:nil];
	[_rocks setData:Data(@"df_value") forKey:Data(@"df_key2") error:nil];

	RocksDBColumnFamily *columnFamily = [_rocks createColumnFamilyWithName:@"new_cf" andOptions:nil];

	[columnFamily setData:Data(@"cf_value") forKey:Data(@"cf_key1") error:nil];
	[columnFamily setData:Data(@"cf_value") forKey:Data(@"cf_key2") error:nil];

	[columnFamily close];
	[_rocks close];

	RocksDBColumnFamilyDescriptor *descriptor = [RocksDBColumnFamilyDescriptor new];
	[descriptor addDefaultColumnFamilyWithOptions:nil];
	[descriptor addColumnFamilyWithName:@"new_cf" andOptions:nil];

	_rocks = [RocksDB databaseAtPath:_path columnFamilies:descriptor andDatabaseOptions:^(RocksDBDatabaseOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBColumnFamily *defaultColumnFamily = _rocks.columnFamilies[0];
	RocksDBColumnFamily *newColumnFamily = _rocks.columnFamilies[1];

	XCTAssertEqualObjects([_rocks dataForKey:Data(@"df_key1") error:nil], Data(@"df_value"));
	XCTAssertEqualObjects([_rocks dataForKey:Data(@"df_key2") error:nil], Data(@"df_value"));
	XCTAssertNil([_rocks dataForKey:Data(@"cf_key1") error:nil]);
	XCTAssertNil([_rocks dataForKey:Data(@"cf_key2") error:nil]);

	XCTAssertEqualObjects([defaultColumnFamily dataForKey:Data(@"df_key1") error:nil], Data(@"df_value"));
	XCTAssertEqualObjects([defaultColumnFamily dataForKey:Data(@"df_key2") error:nil], Data(@"df_value"));

	XCTAssertNil([defaultColumnFamily dataForKey:Data(@"cf_key1") error:nil]);
	XCTAssertNil([defaultColumnFamily dataForKey:Data(@"cf_key2") error:nil]);

	XCTAssertEqualObjects([newColumnFamily dataForKey:Data(@"cf_key1") error:nil], Data(@"cf_value"));
	XCTAssertEqualObjects([newColumnFamily dataForKey:Data(@"cf_key2") error:nil], Data(@"cf_value"));

	XCTAssertNil([newColumnFamily dataForKey:Data(@"df_key1") error:nil]);
	XCTAssertNil([newColumnFamily dataForKey:Data(@"df_key2") error:nil]);

	[newColumnFamily deleteDataForKey:Data(@"cf_key1") error:nil];
	XCTAssertNil([newColumnFamily dataForKey:Data(@"cf_key1") error:nil]);

	[newColumnFamily deleteDataForKey:Data(@"cf_key1") error:nil];
	XCTAssertNil([newColumnFamily dataForKey:Data(@"cf_key1") error:nil]);

	[defaultColumnFamily close];
	[newColumnFamily close];
}

- (void)testColumnFamilies_WriteBatch
{
	RocksDBColumnFamilyDescriptor *descriptor = [RocksDBColumnFamilyDescriptor new];
	[descriptor addDefaultColumnFamilyWithOptions:nil];
	[descriptor addColumnFamilyWithName:@"new_cf" andOptions:nil];

	_rocks = [RocksDB databaseAtPath:_path columnFamilies:descriptor andDatabaseOptions:^(RocksDBDatabaseOptions *options) {
		options.createIfMissing = YES;
		options.createMissingColumnFamilies = YES;
	}];

	RocksDBColumnFamily *defaultColumnFamily = _rocks.columnFamilies[0];
	RocksDBColumnFamily *newColumnFamily = _rocks.columnFamilies[1];

	[newColumnFamily setData:Data(@"xyz_value") forKey:Data(@"xyz") error:nil];

	RocksDBWriteBatch *batch = [newColumnFamily writeBatch];

	[batch setData:Data(@"cf_value1") forKey:Data(@"cf_key1")];
	[batch setData:Data(@"df_value") forKey:Data(@"df_key") inColumnFamily:defaultColumnFamily];
	[batch setData:Data(@"cf_value2") forKey:Data(@"cf_key2")];
	[batch deleteDataForKey:Data(@"xyz") inColumnFamily:defaultColumnFamily];
	[batch deleteDataForKey:Data(@"xyz")];

	[_rocks applyWriteBatch:batch writeOptions:nil error:nil];

	XCTAssertEqualObjects([defaultColumnFamily dataForKey:Data(@"df_key") error:nil], Data(@"df_value"));
	XCTAssertNil([defaultColumnFamily dataForKey:Data(@"df_key1") error:nil]);
	XCTAssertNil([defaultColumnFamily dataForKey:Data(@"df_key2") error:nil]);

	XCTAssertEqualObjects([newColumnFamily dataForKey:Data(@"cf_key1") error:nil], Data(@"cf_value1"));
	XCTAssertEqualObjects([newColumnFamily dataForKey:Data(@"cf_key2") error:nil], Data(@"cf_value2"));
	XCTAssertNil([newColumnFamily dataForKey:Data(@"df_key") error:nil]);

	XCTAssertNil([defaultColumnFamily dataForKey:Data(@"xyz") error:nil]);
	XCTAssertNil([newColumnFamily dataForKey:Data(@"xyz") error:nil]);

	[defaultColumnFamily close];
	[newColumnFamily close];
}

- (void)testColumnFamilies_Iterator
{
	RocksDBColumnFamilyDescriptor *descriptor = [RocksDBColumnFamilyDescriptor new];
	[descriptor addDefaultColumnFamilyWithOptions:nil];
	[descriptor addColumnFamilyWithName:@"new_cf" andOptions:nil];

	_rocks = [RocksDB databaseAtPath:_path columnFamilies:descriptor andDatabaseOptions:^(RocksDBDatabaseOptions *options) {
		options.createIfMissing = YES;
		options.createMissingColumnFamilies = YES;
	}];

	RocksDBColumnFamily *defaultColumnFamily = _rocks.columnFamilies[0];
	RocksDBColumnFamily *newColumnFamily = _rocks.columnFamilies[1];

	[defaultColumnFamily setData:Data(@"df_value1") forKey:Data(@"df_key1") error:nil];
	[defaultColumnFamily setData:Data(@"df_value2") forKey:Data(@"df_key2") error:nil];

	[newColumnFamily setData:Data(@"cf_value1") forKey:Data(@"cf_key1") error:nil];
	[newColumnFamily setData:Data(@"cf_value2") forKey:Data(@"cf_key2") error:nil];

	RocksDBIterator *dfIterator = [defaultColumnFamily iterator];

	NSMutableArray *actual = [NSMutableArray array];
	for ([dfIterator seekToFirst]; [dfIterator isValid]; [dfIterator next]) {
		[actual addObject:Str([dfIterator key])];
		[actual addObject:Str([dfIterator value])];
	}

	NSArray *expected = @[ @"df_key1", @"df_value1", @"df_key2", @"df_value2" ];
	XCTAssertEqualObjects(actual, expected);

	[dfIterator close];

	RocksDBIterator *cfIterator = [newColumnFamily iterator];

	actual = [NSMutableArray array];
	for ([cfIterator seekToFirst]; [cfIterator isValid]; [cfIterator next]) {
		[actual addObject:Str([cfIterator key])];
		[actual addObject:Str([cfIterator value])];
	}

	expected = @[ @"cf_key1", @"cf_value1", @"cf_key2", @"cf_value2" ];
	XCTAssertEqualObjects(actual, expected);

	[cfIterator close];

	[defaultColumnFamily close];
	[newColumnFamily close];
}

@end

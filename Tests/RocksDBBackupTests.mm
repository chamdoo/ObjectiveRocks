//
//  RocksDBBackupTests.m
//  ObjectiveRocks
//
//  Created by Iska on 02/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBTests.h"

@interface RocksDBBackupTests : RocksDBTests

@end

@implementation RocksDBBackupTests

- (void)testBackup_Create
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:_backupPath];

	XCTAssertTrue(exists);
}

- (void)testBackup_BackupInfo
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	NSArray *backupInfo = [backupEngine backupInfo];

	XCTAssertNotNil(backupInfo);
	XCTAssertEqual(backupInfo.count, 1);

	RocksDBBackupInfo *info = backupInfo[0];

	XCTAssertEqual(info.backupId, 1);
}

- (void)testBackup_BackupInfo_Multiple
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	NSArray *backupInfo = [backupEngine backupInfo];

	XCTAssertNotNil(backupInfo);
	XCTAssertEqual(backupInfo.count, 3);

	XCTAssertEqual([backupInfo[0] backupId], 1);
	XCTAssertEqual([backupInfo[1] backupId], 2);
	XCTAssertEqual([backupInfo[2] backupId], 3);
}

- (void)testBackup_PurgeBackups
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	[backupEngine purgeOldBackupsKeepingLast:2 error:nil];

	NSArray *backupInfo = [backupEngine backupInfo];

	XCTAssertNotNil(backupInfo);
	XCTAssertEqual(backupInfo.count, 2);

	XCTAssertEqual([backupInfo[0] backupId], 2);
	XCTAssertEqual([backupInfo[1] backupId], 3);
}

- (void)testBackup_DeleteBackup
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	[backupEngine deleteBackupWithId:2 error:nil];

	NSArray *backupInfo = [backupEngine backupInfo];

	XCTAssertNotNil(backupInfo);
	XCTAssertEqual(backupInfo.count, 2);

	XCTAssertEqual([backupInfo[0] backupId], 1);
	XCTAssertEqual([backupInfo[1] backupId], 3);
}

- (void)testBackup_Restore
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 10") forKey:Data(@"key 1") error:nil];
	[_rocks setData:Data(@"value 20") forKey:Data(@"key 2") error:nil];
	[_rocks setData:Data(@"value 30") forKey:Data(@"key 3") error:nil];

	[_rocks close];

	[backupEngine restoreBackupToDestinationPath:_restorePath error:nil];

	RocksDB *backupRocks = [RocksDB databaseAtPath:_restorePath andDBOptions:nil];

	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 1") error:nil], Data(@"value 1"));
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 2") error:nil], Data(@"value 2"));
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 3") error:nil], Data(@"value 3"));

	[backupRocks close];
}

- (void)testBackup_Restore_Specific
{
	_rocks = [RocksDB databaseAtPath:_path andDBOptions:^(RocksDBOptions *options) {
		options.createIfMissing = YES;
	}];

	RocksDBBackupEngine *backupEngine = [[RocksDBBackupEngine alloc] initWithPath:_backupPath];

	[_rocks setData:Data(@"value 1") forKey:Data(@"key 1") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 2") forKey:Data(@"key 2") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks setData:Data(@"value 3") forKey:Data(@"key 3") error:nil];
	[backupEngine createBackupForDatabase:_rocks error:nil];

	[_rocks close];

	[backupEngine restoreBackupWithId:1 toDestinationPath:_restorePath error:nil];

	RocksDB *backupRocks = [RocksDB databaseAtPath:_restorePath andDBOptions:nil];

	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 1") error:nil], Data(@"value 1"));
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 2") error:nil], nil);
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 3") error:nil], nil);

	[backupRocks close];

	[backupEngine restoreBackupWithId:2 toDestinationPath:_restorePath error:nil];

	backupRocks = [RocksDB databaseAtPath:_restorePath andDBOptions:nil];

	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 1") error:nil], Data(@"value 1"));
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 2") error:nil], Data(@"value 2"));
	XCTAssertEqualObjects([backupRocks dataForKey:Data(@"key 3") error:nil], nil);

	[backupRocks close];
}

@end

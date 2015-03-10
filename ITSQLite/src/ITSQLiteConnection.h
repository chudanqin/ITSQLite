//
//  ITSQLiteConnection.h
//  ITSQLite
//
//  Created by cdq on 19/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#define ITSQLiteLogEnabled  DEBUG

/* not thread safe, you should:
 use in a single thread(main thread) OR use in a custom dispatch queue
 sqlite3_busy_timeout
 sqlite3_config SQLITE_CONFIG_MULTITHREAD or SQLITE_CONFIG_SERIALIZE or SQLITE_CONFIG_SINGLETHREAD */

@interface ITSQLiteConnection : NSObject

@property (nonatomic, strong) id userInfo;

- (id)initWithPath:(NSString *)path;
- (NSString *)sqlitePath;
- (sqlite3 *)sqlite;
//- (void)printInternalError:(const char *)sql;
- (int)openWithFlags:(int)flags;
- (BOOL)isOpen;
- (int)close;
/** return SQLITE_OK if operation succeeded, or SQLITE_xxx error codes if operation failed; */
- (int)executeSQL:(const char *)sql withBlock:(int (^)(sqlite3_stmt *stmt))block;
/** simply call sqlite3_exec */
- (int)executeSQL:(const char *)sql;

@end

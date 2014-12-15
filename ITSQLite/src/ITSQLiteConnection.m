//
//  ITSQLiteConnection.m
//  ITSQLite
//
//  Created by cdq on 19/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "ITSQLiteConnection.h"

#if ITSQLiteLogEnabled
static void ITSQLiteErrorLogCallback(void *pArg, int iErrCode, const char *zMsg){
    NSLog(@"ITSQLite Error:(%d) %s", iErrCode, zMsg);
}
#endif

@interface ITSQLiteConnection () {
@private
    sqlite3 *_sqlite;
}
@property (nonatomic, copy) NSString *sqlitePath;
@end

@implementation ITSQLiteConnection

+ (void)load {
#if ITSQLiteLogEnabled
    sqlite3_config(SQLITE_CONFIG_LOG, ITSQLiteErrorLogCallback, NULL);
#endif
}

- (void)dealloc {
    [self close];
}

- (id)initWithPath:(NSString *)path {
    if(self = [super init]) {
        _sqlitePath = path;
    }
    return self;
}

- (NSString *)sqlitePath {
    return _sqlitePath;
}

- (const char *)sqliteName {
    if (_sqlitePath == nil) {
        return ":memory:"; // create database in memory
    }
    if ([_sqlitePath length] == 0) {
        return ""; // create database with a temp file
    }
    return [_sqlitePath fileSystemRepresentation];
}

- (sqlite3 *)sqlite {
    return _sqlite;
}

/*
- (void)printInternalError:(const char *)sql {
    const char *errmsg;
    if(_sqlite) {
        errmsg = sqlite3_errmsg(_sqlite);
    } else {
        errmsg = "db not open";
    }
    NSLog(@"sqlite error: (%s) on: (%s)", errmsg, sql);
}
*/

- (int)openWithFlags:(int)flags {
    //default flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;
    int rc = SQLITE_OK;
    if(!_sqlite) {
        if(flags == 0) {
            rc = sqlite3_open([self sqliteName], &_sqlite);
        } else {
            rc = sqlite3_open_v2([self sqliteName], &_sqlite, flags, NULL);
        }
        if(rc != SQLITE_OK) {
            _sqlite = NULL;
        }
    }
    return rc;
}

- (BOOL)isOpen {
    return _sqlite != NULL;
}

- (int)close {
    int rc = SQLITE_OK;
    if(_sqlite) {
        rc = sqlite3_close(_sqlite);
        _sqlite = NULL;
    }
    return rc;
}

- (int)executeSQL:(const char *)sql withBlock:(int (^)(sqlite3_stmt *stmt))block {
	sqlite3_stmt *stmt = NULL;
    int rc;
	if ((rc = sqlite3_prepare_v2(_sqlite, sql, -1, &stmt, NULL)) == SQLITE_OK) {
        if(block) {
            rc = block(stmt);
        } else {
            rc = sqlite3_step(stmt);
        }
    }
    if(rc != SQLITE_DONE && rc != SQLITE_ROW && rc != SQLITE_OK) {
        sqlite3_finalize(stmt);
        return rc;
    }
    return sqlite3_finalize(stmt);
}

- (int)executeSQL:(const char *)sql {
    return sqlite3_exec(_sqlite, sql, NULL, NULL, NULL);
}

- (int)setUpdateHooker:(void *)hooker callBack:(void(*)(void *, int, char const *, char const *, sqlite3_int64))callBack {
    if(_sqlite) {
        sqlite3_update_hook(_sqlite, callBack, hooker);
        return SQLITE_OK;
    }
    return SQLITE_ERROR;
}

@end

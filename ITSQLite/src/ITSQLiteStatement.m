//
//  ITSQLiteStatement.m
//  ITSQLite
//
//  Created by cdq on 9/1/14.
//  Copyright (c) 2014 cdq. All rights reserved.
//

#import "ITSQLiteStatement.h"

@interface ITSQLiteStatement () {
@private
    sqlite3_stmt *_stmt;
}
@end

@implementation ITSQLiteStatement

- (void)dealloc {
    [self close];
}

- (id)initWithStatement:(sqlite3_stmt *)stmt {
    if (self = [super init]) {
        _stmt = stmt;
    }
    return self;
}

- (int)bindInt:(int)value atIndex:(int)index {
    return sqlite3_bind_int(_stmt, index, value);
}

- (int)bindLongLong:(long long)value atIndex:(int)index {
    return sqlite3_bind_int64(_stmt, index, value);
}

- (int)bindDouble:(double)value atIndex:(int)index {
    return sqlite3_bind_double(_stmt, index, value);
}

- (int)bindString:(NSString *)value atIndex:(int)index {
    return sqlite3_bind_text(_stmt, index, [value UTF8String], -1, SQLITE_STATIC);
}

- (int)bindData:(NSData *)data atIndex:(int)index {
    return sqlite3_bind_blob(_stmt, index, [data bytes], (int)[data length], SQLITE_STATIC);
}

- (int)bindWithValueBinder:(id <ITSQLiteBindable>)binder {
    return [binder bind:_stmt];
}

- (int)step {
    return sqlite3_step(_stmt);
}

- (ITSQLiteResultSet *)executeQuery {
    ITSQLiteResultSet *rs = [[ITSQLiteResultSet alloc] initWithStatement:_stmt finalizeOnClose:NO];
    rs.userInfo = self;
    return rs;
}

- (int)reset {
    return sqlite3_reset(_stmt);
}

- (int)clearBindings {
    return sqlite3_clear_bindings(_stmt);
}

- (void)close {
    sqlite3_finalize(_stmt);
    _stmt = NULL;
}

@end

@implementation ITSQLiteConnection (ITSQLiteStatement)

- (ITSQLiteStatement *)prepareSQL:(const char *)sql {
    sqlite3_stmt *stmt = NULL;
    int rc;

	if ((rc = sqlite3_prepare_v2([self sqlite],
                                 sql,
                                 -1,
                                 &stmt,
                                 NULL)) == SQLITE_OK) {
        return [[ITSQLiteStatement alloc] initWithStatement:stmt];
    }
    return nil;
}

- (ITSQLiteResultSet *)query:(const char *)query withValueBinder:(id <ITSQLiteBindable>)binder {
    ITSQLiteStatement *statement = [self prepareSQL:query];
    int rc = [statement bindWithValueBinder:binder];
    if (rc != SQLITE_OK) {
        return nil;
    }
    return [statement executeQuery];
}

@end
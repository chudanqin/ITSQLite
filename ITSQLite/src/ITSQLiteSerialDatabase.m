//
//  ITSQLiteSerialDatabase.m
//  ITSQLite
//
//  Created by cdq on 31/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import "ITSQLiteSerialDatabase.h"

#if TARGET_OS_IPHONE

// Compiling for iOS

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000   // iOS 6.0 or later
#define ITSQLITE_GCD_RETAIN(obj)
#define ITSQLITE_GCD_RELEASE(obj)
#else                                           // iOS 5.X or earlier
#define ITSQLITE_GCD_RETAIN(obj)        dispatch_retain(obj)
#define ITSQLITE_GCD_RELEASE(obj)       dispatch_release(obj)
#endif

#else

// Compiling for Mac OS X

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080       // Mac OS X 10.8 or later
#define ITSQLITE_GCD_RETAIN(obj)
#define ITSQLITE_GCD_RELEASE(obj)
#else                                           // Mac OS X 10.7 or earlier
#define ITSQLITE_GCD_RETAIN(obj)        dispatch_retain(obj)
#define ITSQLITE_GCD_RELEASE(obj)       dispatch_release(obj)
#endif

#endif

/////////////////////////////////////////////////

@interface ITSQLiteSerialDatabase () {
    void *_isTargetQueueKey;
    dispatch_queue_t _queue;
}
@end

@implementation ITSQLiteSerialDatabase

- (void)dealloc {
    [self close];
    if (_queue != NULL) {
        ITSQLITE_GCD_RELEASE(_queue);
        _queue = NULL;
    }
}

- (id)initWithQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        if (!queue) {
            queue = dispatch_queue_create(NULL, NULL);
        } else {
            ITSQLITE_GCD_RETAIN(queue);
        }
        _isTargetQueueKey = &_isTargetQueueKey;
        dispatch_queue_set_specific(queue, _isTargetQueueKey, (__bridge void *)(self), NULL);
        _queue = queue;
    }
    return self;
}

- (id)init {
    return [self initWithQueue:NULL];
}

- (BOOL)openWithConnection:(ITSQLiteConnection *)connection
           completionBlock:(void (^)(ITSQLiteConnection *conn))block {
    BOOL __block result = YES;
    [self executeWithBlock:^(ITSQLiteConnection *conn) {
        if (![connection isOpen]) {
            result = [connection openWithFlags:0] == SQLITE_OK;
        }
        if (result) {
            _connection = connection;
            if (block) {
                block(connection);
            }
        }
    }];
    return result;
}

- (void)executeWithBlock:(void (^)(ITSQLiteConnection *conn))block {
    if(dispatch_get_specific(_isTargetQueueKey) == ((__bridge void *)self)) {
        block(_connection);
    } else {
        dispatch_sync(_queue, ^() {
            block(_connection);
        });
    }
}

- (void)executeAsyncWithBlock:(void (^)(ITSQLiteConnection *conn))block {
    dispatch_async(_queue, ^() {
        block(_connection);
    });
}

- (BOOL)close {
    BOOL __block result;
    [self executeWithBlock:^(ITSQLiteConnection *conn) {
        result = [conn close];
    }];
    return result;
}

/*
 - (void)updateDatabase:(const char *)database
 table:(const char *)table
 action:(int)action
 rowID:(sqlite3_int64)rowID {
 // TODO
 }
 
 static void sqliteUpdateHook(void *hooker, int action, const char *database, const char *table, sqlite3_int64 rowID) {
 ITSQLiteDatabase *sdb = (ITSQLiteDatabase *)hooker;
 [sdb updateDatabase:database table:table action:action rowID:rowID];
 }
 
 - (int)enableUpdateHook:(BOOL)enabled {
 __block int ret;
 [self executeWithBlock:^(SQLConnection *conn) {
 if(enabled) {
 ret = [conn setUpdateHooker:self callBack:&sqliteUpdateHook];
 } else {
 ret = [conn setUpdateHooker:NULL callBack:NULL];
 }
 }];
 return ret;
 }
 */

@end

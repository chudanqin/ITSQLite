//
//  ITSQLiteSerialDatabase.h
//  ITSQLite
//
//  Created by cdq on 31/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteConnection.h"

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

@interface ITSQLiteSerialDatabase : NSObject

- (id)initWithQueue:(dispatch_queue_t)queue; // a SERIAL queue
- (ITSQLiteConnection *)connection;
- (BOOL)openWithConnection:(ITSQLiteConnection *)connection
           completionBlock:(void (^)(ITSQLiteConnection *conn))block;
- (void)executeWithBlock:(void (^)(ITSQLiteConnection *conn))block;
- (void)executeAsyncWithBlock:(void (^)(ITSQLiteConnection *conn))block;
- (BOOL)close;

@end

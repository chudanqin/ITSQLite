//
//  ITSQLiteSerialDatabase.h
//  ITSQLite
//
//  Created by cdq on 31/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteConnection.h"

@interface ITSQLiteSerialDatabase : NSObject

@property (nonatomic, readonly) ITSQLiteConnection *connection;

- (id)initWithQueue:(dispatch_queue_t)queue; // a SERIAL queue
- (BOOL)openWithConnection:(ITSQLiteConnection *)connection
           completionBlock:(void (^)(ITSQLiteConnection *conn))block;
- (void)executeWithBlock:(void (^)(ITSQLiteConnection *conn))block;
- (void)executeAsyncWithBlock:(void (^)(ITSQLiteConnection *conn))block;
- (BOOL)close;

@end

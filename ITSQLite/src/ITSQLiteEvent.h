//
//  ITSQLiteEvent.h
//  mihua
//
//  Created by cdq on 23/1/15.
//  Copyright (c) 2015 flk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteConnection.h"

/////////////////////////////////////////////////

typedef NS_ENUM(int, ITSQLiteOperation) {
    ITSQLiteOperationInsert = 1,
    ITSQLiteOperationDelete,
    ITSQLiteOperationUpdate,
};

@interface ITSQLiteEvent : NSObject

@property (nonatomic, readonly) ITSQLiteConnection *connection;
@property (nonatomic, readonly) ITSQLiteOperation operation;
@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSArray *affectedData; // usually @[@{@"k0": @"v0"}, ...] or nil if unable to identify which rows are affected
@property (nonatomic, strong) id userInfo;

- (instancetype)initWithConnection:(ITSQLiteConnection *)conn
                         operation:(ITSQLiteOperation)op
                         tableName:(NSString *)table
                      affectedData:(NSArray *)data;

@end

@interface NSDictionary (ITSQLiteEvent)
- (ITSQLiteEvent *)SQLiteEvent;
@end

@interface NSNotificationCenter (ITSQLiteEvent)
- (void)postSQLiteEvent:(ITSQLiteEvent *)event name:(NSString *)name object:(id)object;
@end

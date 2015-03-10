//
//  ITSQLiteEvent.m
//  mihua
//
//  Created by cdq on 23/1/15.
//  Copyright (c) 2015 flk. All rights reserved.
//

#import "ITSQLiteEvent.h"

const NSString *kITSQLiteEventKey = @"ITSQLite.event";

@interface ITSQLiteEvent ()
@end

@implementation ITSQLiteEvent

- (instancetype)initWithConnection:(ITSQLiteConnection *)conn
                         operation:(ITSQLiteOperation)op
                         tableName:(NSString *)table
                      affectedData:(NSArray *)data {
    NSParameterAssert(conn && table);
    self = [super init];
    if (self) {
        _connection = conn;
        _operation = op;
        _tableName = [table copy];
        _affectedData = [data copy];
    }
    return self;
}

@end

@implementation NSDictionary (ITSQLiteEvent)

- (ITSQLiteEvent *)SQLiteEvent {
    return [self objectForKey:kITSQLiteEventKey];
}

@end

@implementation NSNotificationCenter (ITSQLiteEvent)

- (void)postSQLiteEvent:(ITSQLiteEvent *)event name:(NSString *)name object:(id)object {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:@{kITSQLiteEventKey: event}];
}

@end

/*
 @interface NSObject (ITSQLiteEvent)
 - (id)SQLiteAffectedRowValueForColumnName:(NSString *)columnName;
 @end
 
 @interface NSDictionary (ITSQLiteEvent)
 @end
 */

/*
 @implementation NSObject (ITSQLiteEvent)
 
 - (id)SQLiteAffectedRowValueForColumnName:(NSString *)columnName {
 return [self valueForKey:columnName];
 }
 
 @end
 
 @implementation NSDictionary (ITSQLiteEvent)
 
 - (id)SQLiteAffectedRowValueForColumnName:(NSString *)columnName {
 return [self objectForKey:columnName];
 }
 
 @end
 */

//
//  ITSQLiteStatement.h
//  ITSQLite
//
//  Created by cdq on 9/1/14.
//  Copyright (c) 2014 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteResultSet.h"
#import "ITSQLiteBinder.h"

@interface ITSQLiteStatement : NSObject

- (int)bindInt:(int)value atIndex:(int)index;

- (int)bindLongLong:(long long)value atIndex:(int)index;

- (int)bindDouble:(double)value atIndex:(int)index;

- (int)bindString:(NSString *)value atIndex:(int)index;

- (int)bindData:(NSData *)data atIndex:(int)index;

- (int)bindWithValueBinder:(id <ITSQLiteBindable>)binder;

- (int)step;

- (ITSQLiteResultSet *)executeQuery;

- (int)reset;

- (int)clearBindings;

- (void)close;

@end

@interface ITSQLiteConnection (ITSQLiteStatement)

- (ITSQLiteStatement *)prepareSQL:(const char *)sql;

- (ITSQLiteResultSet *)query:(const char *)query withValueBinder:(id <ITSQLiteBindable>)binder;

@end
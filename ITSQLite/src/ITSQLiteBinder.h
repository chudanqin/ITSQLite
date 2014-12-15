//
//  ITSQLiteBinder.h
//  ITSQLite
//
//  Created by cdq on 23/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteConnection.h"

@protocol ITSQLiteBindable

- (NSUInteger)countToBind;
- (int)boundIndexAtPosition:(int)index;
- (id)boundValueAtIndex:(int)index;
- (BOOL)hasMoreValueToBind:(int)index;
- (int)bind:(sqlite3_stmt *)stmt;

@end

/** Abstract class */
@interface ITSQLiteBinder : NSObject <ITSQLiteBindable>

/** index can't be greater than the result returned by sqlite3_limit() */
@property (nonatomic, strong) NSIndexPath *boundIndexPath;

@end

@interface ITSQLiteArrayBinder : ITSQLiteBinder

@property (nonatomic, strong) NSArray *boundValues;

- (instancetype)initWithValues:(NSArray *)values;

@end

@interface ITSQLiteObjectBinder : ITSQLiteBinder

@property (nonatomic, strong) id boundObject;
@property (nonatomic, strong) NSArray *boundKeys;

- (instancetype)initWithObject:(id)object keys:(NSArray *)keys;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface ITSQLiteConnection (ITSQLiteBinder)
- (int)executeSQL:(const char *)sql withBoundValues:(NSArray *)boundValues;
- (int)executeSQL:(const char *)sql withBinder:(id<ITSQLiteBindable>)binder;
- (int)executeSQL:(const char *)sql withObjects:(NSArray *)objects keys:(NSArray *)keys;
@end

@interface NSObject (ITSQLiteBinder)
- (id)ITSQLiteBoundValueForKey:(NSString *)key;
@end

@interface NSDictionary (ITSQLiteBinder)
@end
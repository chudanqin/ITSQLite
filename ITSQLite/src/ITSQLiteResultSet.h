//
//  SQLResultSet.h
//  mixin
//
//  Created by cdq on 27/6/13.
//  Copyright (c) 2013 chudanqin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteConnection.h"

@interface ITSQLiteResultSet : NSObject

@property (nonatomic, strong) id userInfo;

- (id)initWithStatement:(sqlite3_stmt *)statement finalizeOnDealloc:(BOOL)finalizeOnDealloc;
- (int)reset;
- (BOOL)next;
- (int)intAtColumn:(int)column;
- (long long)longLongAtColumn:(int)column;
- (double)doubleAtColumn:(int)column;
- (const unsigned char *)UTF8StringAtColumn:(int)column;
- (NSString *)stringAtColumn:(int)column;
- (const void *)UTF16StringAtColumn:(int)column;
- (NSData *)dataAtColumn:(int)column;
- (const void *)blobAtColumn:(int)column;
- (int)numberOfBytesAtColumn:(int)column;
- (int)numberOfBytes16AtColumn:(int)column;
- (int)typeAtColumn:(int)column;
- (id)valueAtColumn:(int)column;
- (id)valueAtColumn:(int)column type:(int)type;
- (NSMutableArray *)nextRow;
- (NSMutableDictionary *)nextResult;
- (id)asObject:(Class)clss;
- (id)nextObject:(Class)clss;
- (NSMutableArray *)allObjects:(Class)clss;

@end

@interface ITSQLiteConnection (ITSQLiteResultSet)
- (ITSQLiteResultSet *)executeQuery:(const char *)query;
@end

@interface NSObject (ITSQLiteResultSet)
- (id)ITSQLiteObjCValueForKey:(NSString *)key
                    resultSet:(ITSQLiteResultSet *)resultSet
                        index:(int)index;
@end

/*
@interface NSArray (ITSQLiteResultSet)
- (int)intAtIndex:(NSUInteger)index;
- (long long)longLongAtIndex:(NSUInteger)index;
- (float)floatAtIndex:(NSUInteger)index;
- (double)doubleAtIndex:(NSUInteger)index;
@end

@interface NSDictionary (ITSQLiteResultSet)
- (int)intForKey:(id)key;
- (long long)longLongForKey:(id)key;
- (float)floatForKey:(id)key;
- (double)doubleForKey:(id)key;
@end
*/

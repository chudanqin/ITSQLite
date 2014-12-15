//
//  SQLResultSet.m
//  mixin
//
//  Created by cdq on 27/6/13.
//  Copyright (c) 2013 chudanqin. All rights reserved.
//

#import "ITSQLiteResultSet.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface ITSQLiteResultSet () {
@private
    sqlite3_stmt *_statement;
    BOOL _finalizeOnDealloc;
}
@property (nonatomic, strong) NSDictionary *columnNameToIndexMap;
@end

@implementation ITSQLiteResultSet

- (void)dealloc {
    [self close];
}

- (id)initWithStatement:(sqlite3_stmt *)statement finalizeOnDealloc:(BOOL)finalizeOnDealloc {
    if (self = [super init]) {
        _statement = statement;
        _finalizeOnDealloc = finalizeOnDealloc;
    }
    return self;
}

- (void)close {
    if (_finalizeOnDealloc) {
        sqlite3_finalize(_statement);
    }
    _statement = NULL;
}

- (int)reset {
    return sqlite3_reset(_statement);
}

- (BOOL)next {
    return sqlite3_step(_statement) == SQLITE_ROW;
}

- (NSDictionary *)columnNameToIndexMap {
    if (!_columnNameToIndexMap) {
        int count = sqlite3_column_count(_statement);
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count*3/2];
        NSString *key;
        for (int i = 0; i < count; i++) {
            key = [NSString stringWithUTF8String:sqlite3_column_name(_statement, i)];
            [dict setObject:@(i) forKey:key];
        }
        _columnNameToIndexMap = dict;
    }
    return _columnNameToIndexMap;
}

- (int)intAtColumn:(int)column {
    return sqlite3_column_int(_statement, column);
}

- (long long)longLongAtColumn:(int)column {
    return sqlite3_column_int64(_statement, column);
}

- (double)doubleAtColumn:(int)column {
    return sqlite3_column_double(_statement, column);
}

- (const unsigned char *)UTF8StringAtColumn:(int)column {
    return sqlite3_column_text(_statement, column);
}

- (NSString *)stringAtColumn:(int)column {
    const unsigned char *cstr = sqlite3_column_text(_statement, column);
    if(cstr == NULL) {
        return nil;
    }
    return [NSString stringWithUTF8String:(const char *)cstr];
}

- (const void *)UTF16StringAtColumn:(int)column {
    return sqlite3_column_text16(_statement, column);
}

- (NSData *)dataAtColumn:(int)column {
    const void *bytes = sqlite3_column_blob(_statement, column);
    NSUInteger length = sqlite3_column_bytes(_statement, column);
    return [NSData dataWithBytes:bytes length:length];
}

- (const void *)blobAtColumn:(int)column {
    return sqlite3_column_blob(_statement, column);
}

- (int)numberOfBytesAtColumn:(int)column {
    return sqlite3_column_bytes(_statement, column);
}

- (int)numberOfBytes16AtColumn:(int)column {
    return sqlite3_column_bytes16(_statement, column);
}

- (int)typeAtColumn:(int)column {
    return sqlite3_column_type(_statement, column);
}

- (id)valueAtColumn:(int)column {
    int type = [self typeAtColumn:column];
    return [self valueAtColumn:column type:type];
}

- (id)valueAtColumn:(int)column type:(int)type {
    if (type == SQLITE_INTEGER) {
        return @([self longLongAtColumn:column]);
    }
    if (type == SQLITE_FLOAT) {
        return @([self doubleAtColumn:column]);
    }
    if (type == SQLITE_TEXT) {
        return [self stringAtColumn:column];
    }
    if (type == SQLITE_BLOB) {
        return [self dataAtColumn:column];
    }
    if (type == SQLITE_NULL) {
        return nil;
    }
    NSAssert(NO, @"unknown sqlite column type at %d", column);
    return nil;
}

- (int)indexForName:(NSString *)name {
    NSNumber *n = [[self columnNameToIndexMap] objectForKey:name];
    if (n) {
        return [n intValue];
    }
    NSAssert(NO, @"no such column: %@", name);
    return -1;
}

- (id)valueForName:(NSString *)name {
    int i = [self indexForName:name];
    if (i >= 0) {
        return [self valueAtColumn:i];
    }
    return nil;
}

- (NSMutableArray *)nextRow {
    if (![self next]) {
        return nil;
    }
    int count = sqlite3_column_count(_statement);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        id value = [self valueAtColumn:i];
        if (value == nil) {
            value = [NSNull null];
        }
        [result addObject:value];
    }
    return result;
}

- (NSMutableDictionary *)nextResult {
    if (![self next]) {
        return nil;
    }
    NSDictionary *dict = [self columnNameToIndexMap];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[dict count]*3/2];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = [self valueAtColumn:[obj intValue]];
        if (value == nil) {
            value = [NSNull null];
        }
        [result setObject:value forKey:key];
    }];
    return result;
}

- (id)nextObject:(Class)clss {
    if (![self next]) {
        return nil;
    }
    return [self asObject:clss];
}

- (id)asObject:(Class)clss {
    id result = [[clss alloc] init];
    NSDictionary *dict = [self columnNameToIndexMap];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = [result ITSQLiteObjCValueForKey:key resultSet:self index:[obj intValue]];
        if (value != nil && value != [NSNull null]) {
            [result setValue:value forKey:key];
        }
    }];
    return result;
}

- (NSMutableArray *)allObjects:(Class)clss {
    int count = sqlite3_column_count(_statement);
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSString *key = [[NSString alloc] initWithUTF8String:sqlite3_column_name(_statement, i)];
        [keys addObject:key];
    }
    NSString *key;
    id value;
    while ([self next]) {
        id obj = [[clss alloc] init];
        for (int i = 0; i < count; i++) {
            key = [keys objectAtIndex:i];
            value = [obj ITSQLiteObjCValueForKey:key resultSet:self index:i];
            if (value != nil && value != [NSNull null]) {
                [obj setValue:value forKey:key];
            }
        }
        [results addObject:obj];
    }
    return results;
}

@end

@implementation ITSQLiteConnection (ITSQLiteResultSet)

- (ITSQLiteResultSet *)executeQuery:(const char *)query {
    sqlite3_stmt *stmt = NULL;
    int rc;
    if ((rc = sqlite3_prepare_v2([self sqlite], query, -1, &stmt, NULL)) == SQLITE_OK) {
        return [[ITSQLiteResultSet alloc] initWithStatement:stmt finalizeOnDealloc:YES];
    }
    return nil;
}

@end

@implementation NSObject (ITSQLiteResultSet)

- (id)ITSQLiteObjCValueForKey:(NSString *)key
                    resultSet:(ITSQLiteResultSet *)resultSet
                        index:(int)index {
    return [resultSet valueAtColumn:index];
}

@end

/*
@implementation NSArray (ITSQLiteResultSet)

- (int)intAtIndex:(NSUInteger)index {
    return [[self objectAtIndex:index] intValue];
}

- (long long)longLongAtIndex:(NSUInteger)index {
    return [[self objectAtIndex:index] longLongValue];
}

- (float)floatAtIndex:(NSUInteger)index {
    return [[self objectAtIndex:index] floatValue];
}

- (double)doubleAtIndex:(NSUInteger)index {
    return [[self objectAtIndex:index] doubleValue];
}

@end

@implementation NSDictionary (ITSQLiteResultSet)

- (int)intForKey:(id)key {
    return [[self objectForKey:key] intValue];
}

- (long long)longLongForKey:(id)key {
    return [[self objectForKey:key] longLongValue];
}

- (float)floatForKey:(id)key {
    return [[self objectForKey:key] floatValue];
}

- (double)doubleForKey:(id)key {
    return [[self objectForKey:key] doubleValue];
}

@end
*/

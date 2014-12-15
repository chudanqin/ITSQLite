//
//  ITSQLiteBinder.m
//  ITSQLite
//
//  Created by cdq on 23/12/13.
//  Copyright (c) 2013 cdq. All rights reserved.
//

#import "ITSQLiteBinder.h"

/*
NSString *NSStringFromITSQLiteType(ITSQLiteType type) {
    switch (type) {
        case ITSQLiteTypeInt32:
        case ITSQLiteTypeInt64:
            return @"INTEGER";
        case ITSQLiteTypeFloat:
            return @"REAL";
        case ITSQLiteTypeText:
            return @"TEXT";
        case ITSQLiteTypeBlob:
            return @"BLOB";
        case ITSQLiteTypeNull:
            return @"NULL";
        case ITSQLiteTypeUndefined:
        default:
            return nil;
    }
}

ITSQLiteType ITSQLiteTypeForObjCType(const char *oct) {
    size_t len = strlen(oct);
    if(len > 0) {
        const char ch = oct[0];
        switch (ch) {
            case 'i':
            case 'I':
            case 'B': // C99 _Bool
            case 'l':
            case 'L':
            case 'c':
            case 'C':
            case 's':
            case 'S':
                return ITSQLiteTypeInt32;
                
            case 'q':
            case 'Q':
                return ITSQLiteTypeInt64;
                
            case 'f':
            case 'd':
                return ITSQLiteTypeFloat;
                
            case '@':
                if(len > 4 && oct[1] == '"' && oct[len-1] == '"') {
                    size_t n = len - 3;
                    char name[n + 1];
                    strncpy(name, oct + 2, n);
                    name[n] = 0;
                    if (strcmp(name, "NSString") == 0) {
                        return ITSQLiteTypeText;
                    }
                    if (strcmp(name, "NSData") == 0) {
                        return ITSQLiteTypeBlob;
                    }
                }
                
            default:
                break;
        }
    }
    return ITSQLiteTypeUndefined;
}
*/

static int ITSQLiteBindValue(sqlite3_stmt *stmt, id value, int index) {
    if ([value isKindOfClass:[NSString class]]) {
        return sqlite3_bind_text(stmt, index, [value UTF8String], -1, SQLITE_STATIC);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        const char *objCType = [value objCType];
        switch (objCType[0]) {
            case 'i':
            case 'I':
            case 'B': // C99 _Bool
            case 'l':
            case 'L':
            case 'c':
            case 'C':
            case 's':
            case 'S':
                return sqlite3_bind_int(stmt, index, [value intValue]);
                
            case 'q':
            case 'Q':
                return sqlite3_bind_int64(stmt, index, [value longLongValue]);
                
            case 'f':
            case 'd':
                return sqlite3_bind_double(stmt, index, [value doubleValue]);
                
            default:
                break;
        }
    } else if ([value isKindOfClass:[NSData class]]) {
        return sqlite3_bind_blob(stmt, index, [value bytes], (int)[value length], SQLITE_STATIC);
    } else if (value == nil || value == [NSNull null]) {
        return sqlite3_bind_null(stmt, index);
    }
    assert(NO);
    return SQLITE_ERROR;
}

@implementation ITSQLiteBinder

- (NSUInteger)countToBind {
    return 0;
}

- (int)boundIndexAtPosition:(int)index {
    NSUInteger i = [[self boundIndexPath] indexAtPosition:index];
    if(i == 0 || i == NSNotFound) {
        return 0;
    }
    return (int)i;
}

- (BOOL)hasMoreValueToBind:(int)index {
    @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
    return NO;
}

- (id)boundValueAtIndex:(int)index {
    @throw [NSException exceptionWithName:@"" reason:@"" userInfo:nil];
    return nil;
}

- (int)bind:(sqlite3_stmt *)stmt {
    id value;
    int boundIndex;
    int maxBoundIndex = 0;
    int resultCode = SQLITE_OK;
    for (int i = 0; [self hasMoreValueToBind:i]; i++) {
        boundIndex = [self boundIndexAtPosition:i];
        if (boundIndex < 0) {
            continue;
        }
        if (boundIndex == 0) {
            maxBoundIndex++;
            boundIndex = maxBoundIndex;
        } else {
            maxBoundIndex = MAX(maxBoundIndex, boundIndex);
        }
        value = [self boundValueAtIndex:i];
        if ((resultCode = ITSQLiteBindValue(stmt, value, boundIndex)) != SQLITE_OK) {
            break;
        }
    }
    return resultCode;
}

@end

@implementation ITSQLiteArrayBinder

- (instancetype)initWithValues:(NSArray *)values {
    if (self = [super init]) {
        _boundValues = values;
    }
    return self;
}

- (NSUInteger)countToBind {
    return [_boundValues count];
}

- (BOOL)hasMoreValueToBind:(int)index {
    return index < [_boundValues count];
}

- (id)boundValueAtIndex:(int)index {
    return [_boundValues objectAtIndex:index];
}

@end

@implementation ITSQLiteObjectBinder

- (instancetype)initWithObject:(id)object keys:(NSArray *)keys {
    if (self = [super init]) {
        _boundObject = object;
        _boundKeys = keys;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithObject:dictionary keys:[dictionary allKeys]];
}

- (NSUInteger)countToBind {
    return [_boundKeys count];
}

- (BOOL)hasMoreValueToBind:(int)index {
    return index < [_boundKeys count];
}

- (id)boundValueAtIndex:(int)index {
    return [_boundObject ITSQLiteBoundValueForKey:[_boundKeys objectAtIndex:index]];
}

@end

@implementation ITSQLiteConnection (ITSQLiteBinder)

- (int)executeSQL:(const char *)sql withBoundValues:(NSArray *)boundValues {
    return [self executeSQL:sql withBinder:[[ITSQLiteArrayBinder alloc] initWithValues:boundValues]];
}

- (int)executeSQL:(const char *)sql withBinder:(id<ITSQLiteBindable>)binder {
    if (!binder) {
        return [self executeSQL:sql];
    }
    return [self executeSQL:sql withBlock:^(sqlite3_stmt *stmt) {
        int rc;
        if((rc = [binder bind:stmt]) != SQLITE_OK) {
            return rc;
        }
        rc = sqlite3_step(stmt);
        sqlite3_clear_bindings(stmt);
        return rc;
    }];
}

- (int)executeSQL:(const char *)sql withObjects:(NSArray *)objects keys:(NSArray *)keys {
    NSParameterAssert([keys count] > 0);
    return [self executeSQL:sql withBlock:^(sqlite3_stmt *stmt) {
        ITSQLiteObjectBinder *binder = [[ITSQLiteObjectBinder alloc] init];
        [binder setBoundKeys:keys];
        int rc;
        for (id obj in objects) {
            [binder setBoundObject:obj];
            if((rc = [binder bind:stmt]) != SQLITE_OK) {
                return rc;
            }
            rc = sqlite3_step(stmt);
            if(rc != SQLITE_DONE && rc != SQLITE_ROW) {
                return rc;
            }
            sqlite3_clear_bindings(stmt);
            rc = sqlite3_reset(stmt);
            if(rc != SQLITE_OK) {
                return rc;
            }
        }
        return SQLITE_OK;
    }];
}

@end

@implementation NSObject (ITSQLiteBinder)

- (id)ITSQLiteBoundValueForKey:(NSString *)key {
    return [self valueForKey:key];
}

@end

@implementation NSDictionary (ITSQLiteBinder)

- (id)ITSQLiteBoundValueForKey:(NSString *)key {
    return [self objectForKey:key];
}

@end

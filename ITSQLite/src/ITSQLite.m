//
//  ITSQLite.m
//  mihua
//
//  Created by cdq on 16/8/14.
//  Copyright (c) 2014 flk. All rights reserved.
//

#import "ITSQLite.h"

#import <objc/runtime.h>

/////////////////////////////////////////////////

static NSString *ITSQLiteInsertPreparedSQL(NSString *conflict,
                                           NSString *table,
                                           NSArray *columns,
                                           NSUInteger countOfValues) {
    NSMutableString *query = [NSMutableString stringWithString:@"INSERT"];
    if ([conflict length] > 0) {
        [query stringByAppendingFormat:@" %@", conflict];
    }
    [query appendFormat:@" INTO %@", table];
    if ([columns count] > 0) {
        [query appendFormat:@" (%@)", [columns componentsJoinedByString:@", "]];
    }
    NSMutableArray *qmValues = [[NSMutableArray alloc] initWithCapacity:countOfValues];
    for (int i = 0; i < countOfValues; i++) {
        [qmValues addObject:@"?"];
    }
    [query appendFormat:@" VALUES (%@);", [qmValues componentsJoinedByString:@", "]];
    
    return query;
}

@implementation ITSQLiteConnection (ITSQLite)

- (ITSQLiteResultSet *)SELECT:(NSString *)what
                         FROM:(NSString *)table
                        WHERE:(NSString *)condition
                 valuesToBind:(NSArray *)valuesToBind {
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT %@", what];
    if ([table length] > 0) {
        [query appendFormat:@" FROM %@", table];
    }
    if ([condition length] > 0) {
        [query appendFormat:@" WHERE %@", condition];
    }
    [query appendString:@";"];

    ITSQLiteArrayBinder *binder = [valuesToBind count] == 0 ? nil : [[ITSQLiteArrayBinder alloc] initWithValues:valuesToBind];
    ITSQLiteStatement *statement = [self prepareSQL:[query UTF8String]];
    int rc = [statement bindWithValueBinder:binder];
    if (rc != SQLITE_OK) {
        return nil;
    }
    return [statement executeQuery];
}

- (int)INSERT:(NSString *)conflict
         INTO:(NSString *)table
       binder:(ITSQLiteObjectBinder *)binder {
    NSUInteger bc = [binder countToBind];
    NSParameterAssert([table length] > 0 && bc > 0);
    NSString *query = ITSQLiteInsertPreparedSQL(conflict,
                                                table,
                                                [binder boundKeys],
                                                bc);

    ITSQLiteStatement *statement = [self prepareSQL:[query UTF8String]];
    int rc = [statement bindWithValueBinder:binder];
    if (rc != SQLITE_OK) {
        return rc;
    }

    return [statement step];
}

- (int)INSERT:(NSString *)conflict
         INTO:(NSString *)table
      COLUMNS:(NSArray *)columns
       VALUES:(NSArray *)values {
    NSUInteger bc = [values count];
    NSParameterAssert([table length] > 0 && bc > 0);
    NSString *query = ITSQLiteInsertPreparedSQL(conflict,
                                                table,
                                                columns,
                                                bc);

    ITSQLiteStatement *statement = [self prepareSQL:[query UTF8String]];
    int rc = [statement bindWithValueBinder:[[ITSQLiteArrayBinder alloc] initWithValues:values]];
    if (rc != SQLITE_OK) {
        return rc;
    }

    return [statement step];
}

- (int)UPDATE:(NSString *)table
           OR:(NSString *)conflict
          SET:(NSDictionary *)keysAndValues
        WHERE:(NSString *)condition conditionValuesToBind:(NSArray *)conditionValuesToBind {
    NSUInteger bc = [keysAndValues count];
    NSParameterAssert(bc > 0);
    NSMutableArray *sets = [[NSMutableArray alloc] initWithCapacity:bc];
    NSMutableArray *valuesToBind = [[NSMutableArray alloc] initWithCapacity:bc];
    [keysAndValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [sets addObject:[NSString stringWithFormat:@"%@=?", key]];
        [valuesToBind addObject:obj];
    }];
    NSMutableString *query;
    query = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@",
             [conflict length] > 0 ? [NSString stringWithFormat:@"OR %@ %@", conflict, table] : table,
             [sets componentsJoinedByString:@", "]];
    if ([condition length] > 0) {
        [query appendFormat:@" WHERE %@", condition];
    }
    [query appendString:@";"];

    [valuesToBind addObjectsFromArray:conditionValuesToBind];

    ITSQLiteStatement *statement = [self prepareSQL:[query UTF8String]];
    int rc = [statement bindWithValueBinder:[[ITSQLiteArrayBinder alloc] initWithValues:valuesToBind]];
    if (rc != SQLITE_OK) {
        return rc;
    }

    return [statement step];
}

- (int)DELETE_FROM:(NSString *)table
             WHERE:(NSString *)condition conditionValuesToBind:(NSArray *)conditionValuesToBind {
    NSParameterAssert([table length] > 0);
    NSMutableString *query = [NSMutableString stringWithFormat:@"DELETE FROM %@", table];
    if ([condition length] > 0) {
        [query appendFormat:@" WHERE %@", condition];
    }
    ITSQLiteArrayBinder *binder = [conditionValuesToBind count] == 0 ? nil : [[ITSQLiteArrayBinder alloc] initWithValues:conditionValuesToBind];
    
    ITSQLiteStatement *statement = [self prepareSQL:[query UTF8String]];
    int rc = [statement bindWithValueBinder:binder];
    if (rc != SQLITE_OK) {
        return rc;
    }
    return [statement step];
}

@end

/////////////////////////////////////////////////
static void ITSQLiteObjectTraverseIvars(Class leaf, BOOL (^block)(Class clss,
                                                                  const char *vname,
                                                                  const char *vtype,
                                                                  int index)) {
    Ivar *ivars;
    unsigned int count;
    unsigned int i;
    const char *vname;
    const char *vtype;
    Class clz = leaf;
    while(clz != [NSObject class]) {
        ivars = class_copyIvarList(clz, &count);
        for(i = 0; i < count; i ++) {
            vname = ivar_getName(ivars[i]);
            vtype = ivar_getTypeEncoding(ivars[i]);
            if(!block(clz, vname, vtype, i)) {
                free(ivars);
                return;
            }
        }
        free(ivars);
        clz = [clz superclass];
    }
}

static NSArray *ITSQLiteMixKeys(NSArray *keys, NSDictionary *keyMap) {
    if([keyMap count] == 0) {
        return keys;
    }
    NSMutableArray *columnKeys = [NSMutableArray arrayWithCapacity:[keys count]];
    NSString *dstKey;
    for(NSString *srcKey in keys) {
        dstKey = [keyMap objectForKey:srcKey];
        if(dstKey != nil) {
            [columnKeys addObject:dstKey];
        } else {
            [columnKeys addObject:srcKey];
        }
    }
    return columnKeys;
}

/////////////////////////////////////////////////

@implementation NSObject (ITSQLite)

- (instancetype)initWithJSON:(NSDictionary *)JSON {
    self = [self init];
    if (self) {
        [self SQLiteUpdateValuesWithJSON:JSON];
    }
    return self;
}

+ (NSMutableArray *)SQLiteObjectsFromJSONArray:(NSArray *)array
                                          keys:(NSArray *)keys
                        keyMapFromJSONToObject:(NSDictionary *)keyMap {
    NSUInteger keyCount = [keys count];
    if (keyCount == 0) {
        keys = [[array lastObject] allKeys];
        keyCount = [keys count];
    }
    NSParameterAssert(keyCount > 0);
    NSArray *objKeys = ITSQLiteMixKeys(keys, keyMap);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    id value;
    for(NSDictionary *dict in array) {
        NSParameterAssert([dict isKindOfClass:[NSDictionary class]]);
        id obj = [[self alloc] init];
        NSString *srcKey;
        NSString *dstKey;
        for(NSUInteger i = 0; i < keyCount; i++) {
            srcKey = [keys objectAtIndex:i];
            value = [dict objectForKey:srcKey];
            dstKey = [objKeys objectAtIndex:i];
            [obj setValue:value forKey:dstKey];
        }
        [result addObject:obj];
    }
    return result;
}

- (void)SQLiteUpdateValuesWithJSON:(NSDictionary *)JSON {
    [JSON enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == [NSNull null]) {
            [self setValue:nil forKey:(NSString *)key];
        } else {
            [self setValue:obj forKey:(NSString *)key];
        }
    }];
}

- (NSString *)SQLiteToString {
    Class clss = [self class];
    NSMutableString *desc = [NSMutableString stringWithString:NSStringFromClass(clss)];
    ITSQLiteObjectTraverseIvars(clss, ^(Class clss,
                                        const char *vname,
                                        const char *vtype,
                                        int index) {
        id value = [self valueForKey:[NSString stringWithUTF8String:vname]];
        [desc appendFormat:@"{%s:%@}", vname, value];
        return YES;
    });
    return desc;
}

- (NSDictionary *)SQLiteJSONPeer:(NSArray *)JSONArray {
    for (NSDictionary *dict in JSONArray) {
        if ([self SQLiteIsEqualToJSON:dict]) {
            return dict;
        }
    }
    return nil;
}

- (BOOL)SQLiteIsEqualToJSON:(NSDictionary *)JSON {
    return NO;
}

@end

@implementation ITSQLiteObject

+ (NSString *)tableName {
    return NSStringFromClass(self);
}

+ (NSString *)columnNameForKey:(const char *)key {
    if (key[0] == '_') {
        return [NSString stringWithUTF8String:(key+1)];
    }
    return [NSString stringWithUTF8String:key];
}

+ (BOOL)includesColumnName:(NSString *)columnName {
    return YES;
}

+ (NSMutableArray *)objectsWithConnection:(ITSQLiteConnection *)connection
                                condition:(NSString *)condition
                             valuesToBind:(NSArray *)valuesToBind {
    return [[connection SELECT:@"*" FROM:[self tableName] WHERE:condition valuesToBind:valuesToBind] allObjects:self];
}

+ (instancetype)objectWithConnection:(ITSQLiteConnection *)connection
                           condition:(NSString *)condition
                        valuesToBind:(NSArray *)valuesToBind {
    return [[connection SELECT:@"*" FROM:[self tableName] WHERE:condition valuesToBind:valuesToBind] nextObject:self];
}

+ (int)deleteWithConnection:(ITSQLiteConnection *)connection
                  condition:(NSString *)condition
      conditionValuesToBind:(NSArray *)conditionValuesToBind {
    return [connection DELETE_FROM:[self tableName] WHERE:condition conditionValuesToBind:conditionValuesToBind];
}

- (id)valueForColumnName:(NSString *)columnName {
    return [self valueForKey:columnName];
}

- (int)insertWithConnection:(ITSQLiteConnection *)connection {
    Class clss = [self class];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    ITSQLiteObjectTraverseIvars(clss, ^(Class clzz,
                                        const char *vname,
                                        const char *vtype,
                                        int index) {
        NSString *columnName = [clzz columnNameForKey:vname];
        if ([clzz includesColumnName:columnName]) {
            id v = [self valueForColumnName:columnName];
            if (v != nil) {
                [keys addObject:columnName];
                [values addObject:v];
            }
        }
        return YES;
    });
    return [connection INSERT:nil INTO:[clss tableName] COLUMNS:keys VALUES:values];
}

- (int)updateWithConnection:(ITSQLiteConnection *)connection
              keysAndValues:(NSDictionary *)keysAndValues
                  condition:(NSString *)condition
      conditionValuesToBind:(NSArray *)conditionValuesToBind {
    int rc = [connection UPDATE:[[self class] tableName]
                             OR:nil
                            SET:keysAndValues
                          WHERE:condition conditionValuesToBind:conditionValuesToBind];
    if (rc == SQLITE_DONE) {
        [self SQLiteUpdateValuesWithJSON:keysAndValues];
    }
    return rc;
}

- (NSString *)description {
    return [self SQLiteToString];
}

- (id)copyWithZone:(NSZone *)zone {
    Class clzz = [self class];
    id obj = [[clzz allocWithZone:zone] init];
    ITSQLiteObjectTraverseIvars(clzz, ^BOOL(Class class, const char *vname, const char *vtype, int index) {
        NSString *key = [NSString stringWithUTF8String:vname];
        id value = [self valueForKey:key];
        [obj setValue:value forKey:key];
        return YES;
    });
    return obj;
}

@end

/////////////////////////////////////////////////

@implementation NSDictionary (ITSQLite)

- (id)SQLiteToObject:(Class)clss {
    id obj = [[clss alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == [NSNull null]) {
            [obj setValue:nil forKey:key];
        } else {
            [obj setValue:obj forKey:key];
        }
    }];
    return obj;
}

@end

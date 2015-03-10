//
//  ITSQLite.h
//  mihua
//
//  Created by cdq on 16/8/14.
//  Copyright (c) 2014 flk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ITSQLiteStatement.h"

/////////////////////////////////////////////////

@interface ITSQLiteConnection (ITSQLite)

- (ITSQLiteResultSet *)SELECT:(NSString *)what
                         FROM:(NSString *)table
                        WHERE:(NSString *)condition
                 valuesToBind:(NSArray *)valuesToBind;

- (int)INSERT:(NSString *)conflict
         INTO:(NSString *)table
       binder:(ITSQLiteObjectBinder *)binder;

- (int)INSERT:(NSString *)conflict
         INTO:(NSString *)table
      COLUMNS:(NSArray *)columns
       VALUES:(NSArray *)values;

- (int)UPDATE:(NSString *)table
           OR:(NSString *)conflict
          SET:(NSDictionary *)keysAndValues
        WHERE:(NSString *)condition conditionValuesToBind:(NSArray *)conditionValuesToBind;

- (int)DELETE_FROM:(NSString *)table
             WHERE:(NSString *)condition conditionValuesToBind:(NSArray *)conditionValuesToBind;

@end

/////////////////////////////////////////////////

@interface NSObject (ITSQLite)

- (instancetype)initWithJSON:(NSDictionary *)JSON;

- (void)SQLiteUpdateValuesWithJSON:(NSDictionary *)JSON;

- (NSDictionary *)SQLiteJSONPeer:(NSArray *)JSONArray;

/** @Override */
- (BOOL)SQLiteIsEqualToJSON:(NSDictionary *)JSON;

- (NSString *)SQLiteToString;

@end

/////////////////////////////////////////////////

@interface ITSQLiteObject : NSObject

+ (NSString *)tableName;

+ (NSString *)columnNameForKey:(const char *)key;

+ (BOOL)includesColumnName:(NSString *)columnName;

+ (NSMutableArray *)objectsWithConnection:(ITSQLiteConnection *)connection
                                condition:(NSString *)condition
                             valuesToBind:(NSArray *)valuesToBind;

+ (instancetype)objectWithConnection:(ITSQLiteConnection *)connection
                           condition:(NSString *)condition
                        valuesToBind:(NSArray *)valuesToBind;

+ (int)deleteWithConnection:(ITSQLiteConnection *)connection
                  condition:(NSString *)condition
      conditionValuesToBind:(NSArray *)conditionValuesToBind;

- (id)valueForColumnName:(NSString *)columnName;

- (int)insertWithConnection:(ITSQLiteConnection *)connection;

- (int)updateWithConnection:(ITSQLiteConnection *)connection
              keysAndValues:(NSDictionary *)keysAndValues
                  condition:(NSString *)condition
      conditionValuesToBind:(NSArray *)conditionValuesToBind;

@end

/////////////////////////////////////////////////

@interface NSDictionary (ITSQLite)

- (id)SQLiteToObject:(Class)clss;

@end


//
//  ITSQLiteMigration.m
//  ITSQLite
//
//  Created by cdq on 6/2/14.
//  Copyright (c) 2014 cdq. All rights reserved.
//

#import "ITSQLiteMigration.h"

@interface ITSQLiteMigration ()
@property (nonatomic, strong) ITSQLiteConnection *connection;
@end

@implementation ITSQLiteMigration

- (id)initWithConnection:(ITSQLiteConnection *)connection {
    if (self = [super init]) {
        self.connection = connection;
    }
    return self;
}

- (int)currentVersion {
    return [_connection userVersion];
}

- (int)latestVersion {
    return 0;
}

- (void)upToLatest:(int)latest {
    [_connection setUserVersion:latest];
}

- (ITSQLiteMigrationStatusEnum)migrate {
    int current = [self currentVersion];
    int latest = [self latestVersion];
    if (current >= latest) {
        return ITSQLiteMigrationStatusAlreadyLatest;
    }
    if (![self doMigrationFromVersion:current toVersion:latest]) {
        return ITSQLiteMigrationStatusFailed;
    }
    [self upToLatest:latest];
    return ITSQLiteMigrationStatusOK;
}

- (BOOL)doMigrationFromVersion:(int)fromVersion toVersion:(int)toVersion {
    return NO;
}

@end

@implementation ITSQLiteConnection (ITSQLiteMigrationManager)

- (int)numberOfTables {
    int __block existedTables = 0;
    [self executeSQL:"SELECT COUNT(*) FROM sqlite_master WHERE type='table';"
           withBlock:^int(sqlite3_stmt *stmt) {
               if (sqlite3_step(stmt) == SQLITE_ROW) {
                   existedTables = sqlite3_column_int(stmt, 0);
               }
               return SQLITE_OK;
           }];
    return existedTables;
}

- (int)userVersion {
    int __block version = -1;
    [self executeSQL:"PRAGMA user_version;" withBlock:^(sqlite3_stmt *stmt) {
        int rc;
        rc = sqlite3_step(stmt);
        version = sqlite3_column_int(stmt, 0);
        return rc;
    }];
    return version;
}

- (void)setUserVersion:(int)userVersion {
    [self executeSQL:[[NSString stringWithFormat:@"PRAGMA user_version=%d;", userVersion] UTF8String]];
}

@end

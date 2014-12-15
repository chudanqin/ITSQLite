//
//  ITSQLiteMigration.h
//  ITSQLite
//
//  Created by cdq on 6/2/14.
//  Copyright (c) 2014 cdq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ITSQLiteConnection.h"

typedef enum ITSQLiteMigrationStatus {
    ITSQLiteMigrationStatusFailed = -1,
    ITSQLiteMigrationStatusOK = 0,
    ITSQLiteMigrationStatusAlreadyLatest = 1,
} ITSQLiteMigrationStatusEnum;


@interface ITSQLiteMigration : NSObject
- (id)initWithConnection:(ITSQLiteConnection *)connection;
- (ITSQLiteConnection *)connection;
- (ITSQLiteMigrationStatusEnum)migrate;
/** @Override */
- (void)upToLatest:(int)latestd;
/** @Override */
- (int)currentVersion;
/** @Override must */
- (int)latestVersion;
/** @Override must */
- (BOOL)doMigrationFromVersion:(int)fromVersion toVersion:(int)toVersion;
@end

@interface ITSQLiteConnection (ITSQLiteMigrationManager)
- (int)numberOfTables;
- (int)userVersion;
- (void)setUserVersion:(int)userVersion;
@end
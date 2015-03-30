# a simple sqlite wrapper for iOS in ObjC
```objc
    int rc;
    // initialize
    ITSQLiteConnection *conn;
    NSString *path = @"your local path";
    conn = [[ITSQLiteConnection alloc] initWithPath:path];
    [conn openWithFlags:0]; // SQLITE_OK
    rc = [conn executeSQL:"CREATE TABLE ITSQLiteTT (ID INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, birth REAL NOT NULL, info BLOB);"]; // SQLITE_OK
    
    // insert row
    ITSQLiteTT *tt = [[ITSQLiteTT alloc] init];
    tt.name = @"unnamed";
    tt.birth = @(0.0);
    tt.info = [@"I have no name" dataUsingEncoding:NSUTF8StringEncoding];
    rc = [tt insertWithConnection:conn]; // SQLITE_DONE
    
    // equavelent to the insertion above
    rc = [conn executeSQL:"INSERT INTO ITSQLiteTT (name, birth, info) VALUES (?, ?, ?);" withBoundValues:@[tt.name, tt.birth, tt.info]]; // SQLITE_OK
    
    // insert multi-rows
    NSDictionary *dict = @{@"name-key": @"unsouled",
                           @"birth-key": @(1000.0)};
    NSArray *arr = @[dict, dict];
    // transaction
    [conn executeSQL:"BEGIN;"]; // SQLITE_OK
    [conn executeSQL:"INSERT INTO ITSQLiteTT (name, birth) VALUES (?, ?);" withObjects:arr keys:@[@"name-key", @"birth-key"]]; // SQLITE_OK
    // commit
    [conn executeSQL:"END;"]; // SQLITE_OK
    
    // query as objects
    arr = [ITSQLiteTT objectsWithConnection:conn condition:nil valuesToBind:nil];
    // return the first row matched, this is useful if this row is unique
    tt = [ITSQLiteTT objectWithConnection:conn condition:@"name=?" valuesToBind:@[@"unnamed"]];
    
    // query as result set
    ITSQLiteResultSet *rs = [conn SELECT:@"*" FROM:@"ITSQLiteTT" WHERE:@"birth=?" valuesToBind:@[@(1000.0)]];
    arr = [rs allObjects:[ITSQLiteTT class]];
    // or ...
    arr = [rs allObjects:[NSMutableDictionary class]];
    
    [conn executeSQL:"DROP TABLE ITSQLiteTT;"]; // SQLITE_OK

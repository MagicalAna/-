//
//  MMCPersistentStorage.m
//  MMCache
//
//  Created by Yuan Ana on 2018/7/8.
//  Copyright © 2018 leon. All rights reserved.
//

#import "MMCPersistentStorage.h"
#import "MMCContainer.h"

static NSInteger countNumber;

NSMutableArray<NSString *> *array;

static int callback(void *NotUsed, int argc, char **argv, char **azColName) {
    int i;
    for(i = 0; i < argc; i++) {
        printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
    }
    printf("\n");
    return 0;
}

static int callback2(void *NotUsed, int argc, char **argv, char **azColName) {
    countNumber++;
    return 0;
}

static int callback3(void *NotUsed, int argc, char **argv, char **azColName) {
    NSString *string = [[NSString alloc] initWithCString:(const char*)argv[0] encoding:NSASCIIStringEncoding];
    [array addObject: string];
    return 0;
}

@implementation MMCPersistentStorage

- (sqlite3 *)openDB {
    @synchronized(self) {
        sqlite3 *db;
        int rc;
    
        rc = sqlite3_open("object.db", &db);
        if(rc != SQLITE_OK) {
            NSAssert(0, @"OPENDB FAIL");
        } else {
            //NSLog(@"OPENDB SUCCESS");
        }
        return db;
    }
}

- (void)createTable {
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int  rc;
        char *sql;

        sql = "create table object("  \
        "id text primary key    not null," \
        "object         blob    not null," \
        "added_time     text    not null," \
        "access_time    text    not null," \
        "level          int     not null," \
        "duration       int     not null," \
        "access_count    int     not null);";
    
        rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
        if( rc != SQLITE_OK ) {
            NSAssert(0, @"CREATE TABLE FAIL");
        } else {
            NSLog(@"CREATE TABLE SUCCESS");
        }
        sqlite3_close(db);
    }
}

- (void)dropTable {
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int  rc;
        char *sql = "drop table object";
        rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
        if( rc != SQLITE_OK ){
            NSAssert(0, @"DROP TABLE FAIL");
        } else {
            NSLog(@"DROP TABLE SUCCESS");
        }
        sqlite3_close(db);
    }
}

- (void)showTable {
    @synchronized(self) {
    sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
    
        const char* data = "Callback function called";
        sql = "SELECT * from object";
        rc = sqlite3_exec(db, sql, callback, (void*)data, &zErrMsg);
        sqlite3_close(db);
    }
}

- (NSString *)getDateTimeTOMilliSeconds: (NSDate *)date {
    @synchronized(self) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSString *currentDateString = [dateFormatter stringFromDate: date];
        return currentDateString;
    }
}

- (NSDate *)getDateTimeFromMilliSeconds: (NSString *) milliSeconds {
    @synchronized(self) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSDate *resDate = [formatter dateFromString: milliSeconds];
        return resDate;
    }
}

- (void)countPlus: (NSString*)id {
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        NSDate *now = [NSDate date];
        NSString *string = [self getDateTimeTOMilliSeconds: now];
        
        sql = "UPDATE object SET access_time = ?, access_count = access_count + 1 WHERE id = ?;";
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK) {
            sqlite3_bind_text(stament, 1, [string UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stament, 2, [id UTF8String], -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stament) == SQLITE_DONE) {
                NSLog(@"update ok");
            } else {
                NSLog(@"%s",sqlite3_errmsg(db));
                /*sqlite3_close(db);
                 return [self saveObject: object];*/
            }
        }
        sqlite3_close(db);
    }
}

#pragma mark - MMCStorageProtocol

- (void)purify {
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int  rc;
        char *sql;
    
        sql = "drop table object";
        rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
        if( rc != SQLITE_OK ){
            NSAssert(0, @"DROP TABLE FAIL");
        } else {
            NSLog(@"DROP TABLE SUCCESS");
        }
    
        sql = "create table object("  \
        "id text primary key    not null," \
        "object         blob    not null," \
        "added_time     text    not null," \
        "access_time    text    not null," \
        "level          int     not null," \
        "duration       int     not null," \
        "access_count    int     not null);";
    
        rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
        if( rc != SQLITE_OK ){
            NSAssert(0, @"CREATE TABLE FAIL");
        } else {
            NSLog(@"CREATE TABLE SUCCESS");
        }
        sqlite3_close(db);
    }
}

- (BOOL)saveObject: (MMCContainer *)object {
    if (!object || !object.id) return NO;
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object.object];
        NSString *addedTimeString = [self getDateTimeTOMilliSeconds: object.addedTime];
        NSString *accessTimeString = [self getDateTimeTOMilliSeconds: object.accessTime];
        int level;
        switch (object.level) {
            case MMCLevelDefault:
                level = 1;
                break;
            case MMCLevelHigh:
                level = 2;
                break;
            case MMCLevelImportant:
                level = 3;
                break;
        }
        int duration = object.duration;
        int accseeCount = (int) object.accessCount;
        
        NSString *sqlStr = @"insert into object(id,object,added_time,access_time,level,duration,access_count)values(?,?,?,?,?,?,?);";
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sqlStr.UTF8String, -1, &stament, NULL);
        if (result == SQLITE_OK) {
            sqlite3_bind_text(stament, 1, [object.id UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_blob(stament, 2, data.bytes, (int)data.length, NULL);
            sqlite3_bind_text(stament, 3, [addedTimeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stament, 4, [accessTimeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(stament, 5, level);
            sqlite3_bind_int(stament, 6, duration);
            sqlite3_bind_int(stament, 7, accseeCount);
            
            if (sqlite3_step(stament) == SQLITE_DONE) {
                NSLog(@"in ok");
            } else {
                NSLog(@"%s",sqlite3_errmsg(db));
            }
        }
        sqlite3_close(db);
        return YES;
    }
}

- (NSInteger)count {
    @synchronized(self) {
        countNumber = 0;
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
        
        sql ="SELECT * from object";
        rc = sqlite3_exec(db, sql, callback2, nil, &zErrMsg);
        if( rc != SQLITE_OK ) {
            fprintf(stderr, "SQL error: %s\n", zErrMsg);
            sqlite3_free(zErrMsg);
        }
        sqlite3_close(db);
    }
    return countNumber;
}

- (MMCContainer *)objectForId: (NSString *)id {
    if (!id) return nil;
    @synchronized(self){
        MMCContainer *container = MMCContainer.new;
        char *sqlStr = "select * from object where id = ?";
        NSData *resultData;
        sqlite3 *mySqlite = [self openDB];
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(mySqlite, sqlStr, -1, &stament, NULL);
        if (result == 0)
            
        {
            sqlite3_bind_text(stament, 1, [id UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(stament) == SQLITE_ROW) {
                const unsigned char *getId = sqlite3_column_text(stament, 0);
                const void *imageValue = sqlite3_column_blob(stament, 1);
                int length = sqlite3_column_bytes(stament, 1);
                const unsigned char *addedTimeString = sqlite3_column_text(stament, 2);
                const unsigned char *accessTimeString = sqlite3_column_text(stament, 3);
                int level = sqlite3_column_int(stament, 4);
                container.duration = sqlite3_column_int(stament, 5);
                container.accessCount = sqlite3_column_int(stament, 6);

                resultData = [[NSData alloc]initWithBytes:imageValue length:length];
                container.object = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
                container.id = [[NSString alloc] initWithCString:(const char*)getId encoding:NSASCIIStringEncoding];
                container.addedTime = [self getDateTimeFromMilliSeconds: [NSString stringWithCString: (const char *)addedTimeString  encoding:NSUTF8StringEncoding]];
                container.accessTime = [self getDateTimeFromMilliSeconds: [NSString stringWithCString: (const char *)accessTimeString  encoding:NSUTF8StringEncoding]];
                switch (level){
                    case 1:
                        container.level = MMCLevelDefault;
                        break;
                    case 2:
                        container.level = MMCLevelHigh;
                        break;
                    case 3:
                        container.level = MMCLevelImportant;
                }
            }
        }
        else
        {
            NSLog(@"sel fs，%d",result);
        }
        if (container) {
            [self countPlus: id];
            container.accessTime = NSDate.date;
            container.accessCount++;
        }
        sqlite3_close(mySqlite);
        sqlite3_finalize(stament);
        return container;
    }
}

- (BOOL)removeObjectForId: (NSString *)id {
    if (!id) return NO;
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql = "DELETE from object where ID = ?; " ;
        sqlite3_stmt *stmt;

        if(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK){
            sqlite3_bind_text(stmt, 1, [id UTF8String], -1, SQLITE_TRANSIENT);
            while(sqlite3_step(stmt) == SQLITE_ROW);
            sqlite3_finalize(stmt);
        }
        else{
            NSLog(@"REMOVE FAIL");
            sqlite3_finalize(stmt);
        }
        return YES;
    }
}

- (MMCContainer *)leastAccessed {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY access_count limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}


- (MMCContainer *)lastAccessed {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY access_count DESC limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}

- (MMCContainer *)firstAdded {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY added_time limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}

- (MMCContainer *)lastAdded {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY added_time DESC limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}

- (MMCContainer *)leastRecentAccessed {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY access_count limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}

- (MMCContainer *)mostAccessed {
    @synchronized (self) {
        NSString *sql = @"SELECT id From object ORDER BY access_count DESC limit 1;";
        NSString *objectId;
        sqlite3 *db = [self openDB];
        if (db == NULL) return nil;
        
        sqlite3_stmt *stament;
        int result = sqlite3_prepare_v2(db, sql.UTF8String, -1 ,&stament, nil);
        if (result == SQLITE_OK) {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                objectId = [NSString stringWithUTF8String: (char *)sqlite3_column_text(stament, 0)];
            }
        }
        sqlite3_close(db);
        return [self objectForId: objectId];
    }
}

- (NSArray <NSString *> *)allIds {
    array = [NSMutableArray arrayWithCapacity:10];
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int rc;
    char *sql = "SELECT id FROM object";
    rc = sqlite3_exec(db, sql, callback3, nil, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }
    sqlite3_close(db);
    return array;
}

@end

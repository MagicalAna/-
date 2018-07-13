//
//  MMCPersistentStorage.m
//  MMCache
//
//  Created by Yuan Ana on 2018/7/8.
//  Copyright © 2018 leon. All rights reserved.
//

#import "MMCPersistentStorage.h"
#import "MMCContainer.h"

static int callback(void *NotUsed, int argc, char **argv, char **azColName){
    int i;
    for(i=0; i<argc; i++){
        printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
    }
    printf("\n");
    return 0;
}

static NSMutableArray<NSString *> *array;

static NSInteger countNumber;

static int callback2(void *NotUsed, int argc, char **argv, char **azColName){
    countNumber++;
    return 0;
}

static int callback3(void *NotUsed, int argc, char **argv, char **azColName){
    NSString *string = [[NSString alloc] initWithCString:(const char*)argv[1] encoding:NSASCIIStringEncoding];
    [array addObject: string];
    return 0;
}

@implementation MMCPersistentStorage

- (void)showTable{
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int rc;
    char *sql;
    const char* data = "Callback function called";
    sql = "SELECT * from object";
    
    /* Execute SQL statement */
    rc = sqlite3_exec(db, sql, callback, (void*)data, &zErrMsg);
    sqlite3_close(db);
}

- (NSDate *)getDateTimeFromMilliSeconds: (int) leftHalf andRightHalf: (int)rightHalf{
    
    long long int miliSeconds = (long long int)leftHalf * 100000000 + (long long int) rightHalf;
    
    NSTimeInterval tempMilli = miliSeconds;
    
    NSTimeInterval seconds = tempMilli/1000.0;//这里的.0一定要加上，不然除下来的数据会被截断导致时间不一致
    
    //NSLog(@"传入的时间戳=%f",seconds);
    
    return [NSDate dateWithTimeIntervalSince1970:seconds];
    
}

//将NSDate类型的时间转换为时间戳,从1970/1/1开始

- (int)getDateTimeTOMilliSeconds:(NSDate *)datetime andRightHalf:(int *)rightHalf{
    
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    
    //NSLog(@"转换的时间戳=%f",interval);
    
    long long totalMilliseconds = interval*1000 ;
    
    //NSLog(@"totalMilliseconds=%llu",totalMilliseconds);
    
    *rightHalf = totalMilliseconds % 100000000;
    return (int)(totalMilliseconds / 100000000);
    
}

- (sqlite3 *)openDB {
        sqlite3 *db;
        int  rc;
    
        /* Open database */
        rc = sqlite3_open("persistentStorage.db", &db);
        if( rc ){
            NSLog(@"Can't open database: %s\n", sqlite3_errmsg(db));
        }else{
            //fprintf(stdout, "Opened database successfully\n");
        }
        return db;
}


- (void)createTable{
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int  rc;
    char *sql;
    /* Create SQL statement */
    sql = "create table object("  \
    "id text primary key    not null," \
    "object         blob    not null," \
    "addedTime1     int     not null," \
    "addedTime2     int     not null," \
    "accessTime1    int     not null," \
    "accessTime2    int     not null," \
    "level          int     not null," \
    "duration       int     not null," \
    "accessCount    int     not null);";
    
    /* Execute SQL statement */
    rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    } else {
        fprintf(stdout, "Table created successfully\n");
    }
    sqlite3_close(db);
}

-(void)countPlus:(NSString*)id andAccessCount:(int)count{
    @synchronized(self){
        count++;
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
        const char* data = "Callback function called";
        
        int left, right;
        NSDate *now = [NSDate date];
        left = [self getDateTimeTOMilliSeconds: now andRightHalf: &right];
        
        /* Create merged SQL statement */
        sql = "insert into object(accessTime1,accessTime2,accessCount)values(?,?,?) where ID = ?";
        
        //伴随指针
        sqlite3_stmt *stament;
        //准备
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK) {
            
            //bind绑定   data转换类型
            // 第1个参数：是前面prepare得到的 sqlite3_stmt * 类型变量。
            
            //        第2个参数：?号的索引。前面prepare的sql语句里有一个?号，假如有多个?号怎么插入？方法就是改变 bind_blob 函数第2个参数。
            //这个参数我写1，表示这里插入的值要替换 stat 的第一个?号（这里的索引从1开始计数，而非从0开始）。如果你有多个?号，就写多个 bind_blob 语句，
            //并改变它们的第2个参数就替换到不同的?号。如果有?号没有替换，sqlite为它取值null。
            
            //        第3个参数：二进制数据起始指针。
            
            //        第4个参数：二进制数据的长度，以字节为单位,如果是二进制类型绝对不可以给-1，必须具体长度。
            
            //        第5个参数：是个析够回调函数，告诉sqlite当把数据处理完后调用此函数来析够你的数据。这个参数我还没有使用过，因此理解也不深刻。
            //但是一般都填NULL，需要释放的内存自己用代码来释放。
            sqlite3_bind_int(stament, 1, left);
            sqlite3_bind_int(stament, 2, right);
            sqlite3_bind_int(stament, 3, count);if (sqlite3_step(stament) == SQLITE_DONE) {
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

- (void)dropTable{
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int  rc;
    char *sql;
    sql = "drop table object";
    rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    } else {
        fprintf(stdout, "Table droped successfully\n");
    }
    sqlite3_close(db);
}

#pragma mark - MMCStorageProtocol

- (BOOL)saveObject:(MMCContainer *)object {
    if (!object || !object.id) return NO;
    @synchronized(self){
        sqlite3 *db = [self openDB];
        
        int addedTimeInt2 , accessTimeInt2;
        /* Open database */
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object.object];
        int addedTimeInt1 = [self getDateTimeTOMilliSeconds:object.addedTime andRightHalf: &addedTimeInt2];
        int accessTimeInt1 = [self getDateTimeTOMilliSeconds:object.accessTime andRightHalf: &accessTimeInt2];
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
        
        NSString *sqlStr = @"insert into object(id,object,addedTime1,addedTime2,accessTime1,accessTime2,level,duration,accessCount)values(?,?,?,?,?,?,?,?,?);";
        //伴随指针
        sqlite3_stmt *stament;
        //准备
        int result = sqlite3_prepare(db, sqlStr.UTF8String, -1, &stament, NULL);
        if (result == SQLITE_OK) {
            
            //bind绑定   data转换类型
            // 第1个参数：是前面prepare得到的 sqlite3_stmt * 类型变量。
            
            //        第2个参数：?号的索引。前面prepare的sql语句里有一个?号，假如有多个?号怎么插入？方法就是改变 bind_blob 函数第2个参数。
            //这个参数我写1，表示这里插入的值要替换 stat 的第一个?号（这里的索引从1开始计数，而非从0开始）。如果你有多个?号，就写多个 bind_blob 语句，
            //并改变它们的第2个参数就替换到不同的?号。如果有?号没有替换，sqlite为它取值null。
            
            //        第3个参数：二进制数据起始指针。
            
            //        第4个参数：二进制数据的长度，以字节为单位,如果是二进制类型绝对不可以给-1，必须具体长度。
            
            //        第5个参数：是个析够回调函数，告诉sqlite当把数据处理完后调用此函数来析够你的数据。这个参数我还没有使用过，因此理解也不深刻。
            //但是一般都填NULL，需要释放的内存自己用代码来释放。
            sqlite3_bind_text(stament, 1, [object.id UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_blob(stament, 2, data.bytes, (int)data.length, NULL);
            sqlite3_bind_int(stament, 3, addedTimeInt1);
            sqlite3_bind_int(stament, 4, addedTimeInt2);
            sqlite3_bind_int(stament, 5, accessTimeInt1);
            sqlite3_bind_int(stament, 6, accessTimeInt2);
            sqlite3_bind_int(stament, 7, level);
            sqlite3_bind_int(stament, 8, duration);
            sqlite3_bind_int(stament, 9, accseeCount);
            
            //执行插入sql语句如果不是查询语句，while改为if，SQLITE_ROW 改为 SQLite_DONE
            if (sqlite3_step(stament) == SQLITE_DONE) {
                NSLog(@"in ok");
            } else {
                NSLog(@"%s",sqlite3_errmsg(db));
                /*sqlite3_close(db);
                return [self saveObject: object];*/
            }
        }
        sqlite3_close(db);
        NSLog(@"%ld",[self count]);
        return YES;
    }
}


- (BOOL)removeObjectForId:(NSString *)id {
    if (!id) return NO;
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
        const char* data = "Callback function called";
        
       
        
        /* Create merged SQL statement */
        sql = "DELETE from object where ID = ?; " ;
        sqlite3_stmt *stmt;
        /* Execute SQL statement */
        if(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK){
            sqlite3_bind_text(stmt, 1, [id UTF8String], -1, SQLITE_TRANSIENT);
            while(sqlite3_step(stmt) == SQLITE_ROW);
            sqlite3_finalize(stmt);
        }
        else{
            NSLog(@"FAQ");
            sqlite3_finalize(stmt);
        }
        return YES;
    }
}


- (MMCContainer *)objectForId:(NSString *)id {
    if (!id) return nil;
    @synchronized(self){
        MMCContainer *container = MMCContainer.new;
        char *sqlStr = "select * from object where id = ?";
        NSData *resultData;
        sqlite3 *mySqlite = [self openDB];
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(mySqlite, sqlStr, -1, &stament, NULL);
        if (result == 0)
            
        {
            sqlite3_bind_text(stament, 1, [id UTF8String], -1, SQLITE_TRANSIENT);
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                const unsigned char *getId = sqlite3_column_text(stament, 1);
                //每次获取blob类型的值，需要同时获得该值的大小
                const void *imageValue = sqlite3_column_blob(stament, 2);
                //每次获取blob类型的值，需要同时获得该值的大小
                int length = sqlite3_column_bytes(stament, 2);
                int addedTimeInt1 = sqlite3_column_int(stament, 3);
                int addedTimeInt2 = sqlite3_column_int(stament, 4);
                int accessTimeInt1 = sqlite3_column_int(stament, 5);
                int accessTimeInt2 = sqlite3_column_int(stament, 6);
                int level = sqlite3_column_int(stament, 7);
                container.duration = sqlite3_column_int(stament, 8);
                container.accessCount = sqlite3_column_int(stament, 9);
                //从byte到NSData
                resultData = [[NSData alloc]initWithBytes:imageValue length:length];
                container.object = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
                container.id = [[NSString alloc] initWithCString:(const char*)getId encoding:NSASCIIStringEncoding];
                container.addedTime = [self getDateTimeFromMilliSeconds: addedTimeInt1 andRightHalf: addedTimeInt2];
                container.accessTime = [self getDateTimeFromMilliSeconds: accessTimeInt1 andRightHalf: accessTimeInt2];
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
            [self countPlus:id andAccessCount:(int)container.accessCount];
            container.accessTime = NSDate.date;
            container.accessCount++;
        }
        //释放资源
        sqlite3_close(mySqlite);
        sqlite3_finalize(stament);
        
        //关闭后给个nil
        mySqlite = nil;
        return container;
    }
}

- (NSInteger)count {
    @synchronized(self){
        countNumber = 0;
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object";
        
        /* Execute SQL statement */
        rc = sqlite3_exec(db, sql, callback2, nil, &zErrMsg);
        if( rc != SQLITE_OK ){
            fprintf(stderr, "SQL error: %s\n", zErrMsg);
            sqlite3_free(zErrMsg);
        }
        sqlite3_close(db);
    }
    return countNumber;
}

- (MMCContainer *)firstAdded {
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object order by addedtime arc limit 1";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}

- (MMCContainer *)lastAdded {
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object order by addedtime desc limit 1";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}

- (MMCContainer *)lastAccessed {
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object order by accesstime desc limit 1";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}

- (MMCContainer *)leastRecentAccessed{
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object order by accesstime arc limit 1";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}

- (MMCContainer *)mostAccessed{
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
        
        
        
        /* Create merged SQL statement */
        sql ="SELECT * from object order by accesscount desc limit 1";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}

- (MMCContainer *)leastAccessed{
    @synchronized(self){
        sqlite3 *db = [self openDB];
        char *sql;
    
    
    
        /* Create merged SQL statement */
        sql ="SELECT * from object order by accesscount";
        const unsigned char *theID = NULL;
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(db, sql, -1, &stament, NULL);
        if (result == SQLITE_OK)
        
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                theID = sqlite3_column_text(stament, 1);
            }
        }
        NSString *string_content = [[NSString alloc] initWithCString:(const char*)theID encoding:NSASCIIStringEncoding];
        sqlite3_close(db);
        return [self objectForId:string_content];
    }
}


- (void)purify {
        [self dropTable];
        [self createTable];
}


- (NSArray <NSString *> *)allIds {
    array = nil;
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int rc;
    char *sql;
    
    
    
    /* Create merged SQL statement */
    sql ="SELECT * from object";
    
    /* Execute SQL statement */
    rc = sqlite3_exec(db, sql, callback3, nil, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }
    sqlite3_close(db);
    return array;
}
    @end
    

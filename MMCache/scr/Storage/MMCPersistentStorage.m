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

@interface MMCPersistentStorage ()

@property (nonatomic, strong) NSMutableOrderedSet <NSString *> *added;
@property (nonatomic, strong) NSMutableOrderedSet <NSString *> *accessed;

@end

@implementation MMCPersistentStorage

-(sqlite3*)openDB{
    sqlite3 *db;
    int  rc;
    
    /* Open database */
    rc = sqlite3_open("persistentStorage.db", &db);
    if( rc ){
        NSLog(@"Can't open database: %s\n", sqlite3_errmsg(db));
    }else{
        fprintf(stdout, "Opened database successfully\n");
    }
    return db;
}

-(void)countPlus:(NSString*)id{
    
}

-(void)createTable{
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int  rc;
    char *sql;
    /* Create SQL statement */
    sql = "create table object("  \
    "id text primary key    not null," \
    "object         blob    not null," \
    "addedTime      text    not null," \
    "accessedTime   text    not null," \
    "level          int     not null," \
    "duration       int     not null," \
    "accessCount    int     not null);";
    
    /* Execute SQL statement */
    rc = sqlite3_exec(db, sql, callback, 0, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }else{
        fprintf(stdout, "Table created successfully\n");
    }
    sqlite3_close(db);
}

- (NSMutableOrderedSet <NSString *> *)added {
    if (!_added) _added = NSMutableOrderedSet.orderedSet;
    return _added;
}


- (NSMutableOrderedSet <NSString *> *)accessed {
    if (!_accessed) _accessed = NSMutableOrderedSet.orderedSet;
    return _accessed;
}

-(void)countPlus:(NSString*)id andAccessCount:(int)accessCount{
    sqlite3 *db = [self openDB];
    char *zErrMsg = 0;
    int rc;
    char *sql;
    const char* data = "Callback function called";
    NSDate *date = NSDate.date;
    
    /* Create merged SQL statement */
    sql = "UPDATE COMPANY set accessCount = accessCount+1 where ID=id; " \
    "UPDATE COMPANY set accessedTime = string where ID=id; ";
    
    /* Execute SQL statement */
    rc = sqlite3_exec(db, sql, callback, (void*)data, &zErrMsg);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }else{
        fprintf(stdout, "Operation done successfully\n");
    }
    sqlite3_close(db);
}

-(NSString*)stringFromDate:(NSDate*)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设置格式：zzz表示时区
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    //NSDate转NSString
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    return currentDateString;
}

-(NSDate*)dateFromString:(NSString*)string{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:sss"];
    //获取当前时间
    
    /**
     *  把字符串时间转换为nsdate
     */
    
    [formatter setDateFormat:@"yyyy-MM-dd HH-mm-sss zzz"];
    
    NSDate *resDate = [formatter dateFromString:string];
    return resDate;
}

#pragma mark - MMCStorageProtocol

- (BOOL)saveObject:(MMCContainer *)object {
    if (!object || !object.id) return NO;
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        
        /* Open database */
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object.object];
        NSString *addedtimeString = [self stringFromDate:object.addedTime];
        NSString *accesstimeString = [self stringFromDate:object.accessTime];
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
        int accseeCount = object.accessCount;
        
        NSString *sqlStr = @"insert into object(id,object,addedTime,accessedTime,level,duration,accessCount)values(?,?,?,?,?,?,?);";
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
            sqlite3_bind_text(stament, 3, [addedtimeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stament, 4, [accesstimeString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(stament, 5, level);
            sqlite3_bind_int(stament, 6, duration);
            sqlite3_bind_int(stament, 7, accseeCount);
            
            //执行插入sql语句如果不是查询语句，while改为if，SQLITE_ROW 改为 SQLite_DONE
            if (sqlite3_step(stament) == SQLITE_DONE) {
                NSLog(@"in ok");
            }
            else
            {
                NSLog(@"%s",sqlite3_errmsg(db));
            }
        [self.added addObject:object.id];
    }
    return YES;
    }
}

- (BOOL)removeObjectForId:(NSString *)id {
    if (!id) return NO;
    @synchronized(self) {
        sqlite3 *db = [self openDB];
        char *zErrMsg = 0;
        int rc;
        char *sql;
        const char* data = "Callback function called";
        
       
        
        /* Create merged SQL statement */
        sql = "DELETE from COMPANY where ID = id; " \
        "SELECT * from COMPANY";
        
        /* Execute SQL statement */
        rc = sqlite3_exec(db, sql, callback, (void*)data, &zErrMsg);
        if( rc != SQLITE_OK ){
            fprintf(stderr, "SQL error: %s\n", zErrMsg);
            sqlite3_free(zErrMsg);
        }else{
            fprintf(stdout, "Operation done successfully\n");
        }
        sqlite3_close(db);
        [self.added removeObject:id];
        [self.accessed removeObject:id];
        return YES;
    }
}

- (MMCContainer *)objectForId:(NSString *)id {
    if (!id) return nil;
    @synchronized(self) {
        MMCContainer *container = MMCContainer.new;
        NSString *sqlStr = @"select * from object where id = id";
        NSData *resultData;
        sqlite3 *mySqlite = [self openDB];
        sqlite3_stmt *stament;
        int result = sqlite3_prepare(mySqlite, sqlStr.UTF8String, -1, &stament, NULL);
        if (result == SQLITE_OK)
            
        {
            while (sqlite3_step(stament) == SQLITE_ROW) {
                //所在的第0列
                char *id = sqlite3_column_text(stament, 1);
                //每次获取blob类型的值，需要同时获得该值的大小
                const void *imageValue = sqlite3_column_blob(stament, 2);
                //每次获取blob类型的值，需要同时获得该值的大小
                int length = sqlite3_column_bytes(stament, 2);
                char *addedTimeString = sqlite3_column_text(stament, 3);
                char *accessTimeString = sqlite3_column_text(stament, 4);
                int level = sqlite3_column_int(stament, 5);
                container.duration = sqlite3_column_int(stament, 6);
                container.accessCount = sqlite3_column_int(stament, 7);
                //从byte到NSData
                resultData = [[NSData alloc]initWithBytes:imageValue length:length];
                container.object = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
                container.id = [[NSString alloc] initWithCString:(const char*)id encoding:NSASCIIStringEncoding];
                container.addedTime = [self dateFromString:[[NSString alloc] initWithCString:(const char*)addedTimeString encoding:NSASCIIStringEncoding]];
                container.addedTime = [self dateFromString:[[NSString alloc] initWithCString:(const char*)accessTimeString encoding:NSASCIIStringEncoding]];
                switch (level){
                    case 1:
                        container.level = MMCLevelDefault;
                        break;
                    case 2:
                        container.level = MMCLevelHigh;
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
            [self countPlus:id andAccessCount:container.accessCount];
            [self.accessed removeObject:container.id];
            [self.accessed addObject:container.id];
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
    @synchronized(self) {
        return 1000;
    }
}

- (MMCContainer *)firstAdded {
    @synchronized(self) {
        NSString *id = self.added.firstObject;
        return [self objectForId:id];
    }
}

- (MMCContainer *)lastAdded {
    @synchronized(self) {
        NSString *id = self.added.lastObject;
        return [self objectForId:id];
    }
}

- (MMCContainer *)lastAccessed {
    @synchronized(self) {
        NSString *id = self.accessed.lastObject;
        return [self objectForId:id];
    }
}

- (MMCContainer *)leastAccessed {
    NSInteger min = INT_MAX;
    MMCContainer *minContainer;
    return minContainer;
}

- (MMCContainer *)mostAccessed {
    NSInteger max = 0;
    MMCContainer *minContainer;
    
    return minContainer;
}

- (MMCContainer *)leastRecentAccessed {
    MMCContainer *lru;
    
    return lru;
}

- (void)purify {
    @synchronized(self) {
        [self dropTable];
        [self createTable];
        self.added    = NSMutableOrderedSet.orderedSet;
        self.accessed = NSMutableOrderedSet.orderedSet;
    }
}


- (NSArray <NSString *> *)allIds {
    return self.added.array;
}

@end

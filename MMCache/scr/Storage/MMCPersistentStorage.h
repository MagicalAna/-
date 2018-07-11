//
//  MMCPersistentStorage.h
//  MMCache
//
//  Created by Yuan Ana on 2018/7/8.
//  Copyright © 2018 leon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMCStorageProtocol.h"


@interface MMCPersistentStorage : NSObject <MMCStorageProtocol>

-(sqlite3*)openDB;
-(void)createTable;
-(NSString*)stringFromDate:(NSDate*)date;
-(void)dropTable;
-(NSDate*)dateFromString:(NSString*)string;
-(void)countPlus:(NSString*)id andAccessCount:(int)accessCount;

@end

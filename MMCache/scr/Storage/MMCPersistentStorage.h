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

- (sqlite3 *)openDB;

- (void)createTable;

- (void)dropTable;

- (void)countPlus: (NSString*)id;

- (NSDate *)getDateTimeFromMilliSeconds: (NSString *) milliSeconds;

- (NSString *)getDateTimeTOMilliSeconds: (NSDate *)date;

- (void)showTable;

@end

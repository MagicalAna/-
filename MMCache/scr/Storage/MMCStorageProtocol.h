//
//  MMCStorageProtocol.h
//  MMCache
//
//  Created by leon on 06/07/2018.
//  Copyright © 2018 leon. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <sqlite3.h>

@class MMCContainer;

@protocol MMCStorageProtocol <NSObject>

@required

- (MMCContainer *)objectForId:(NSString *)id;   //访问指定ID的储存

- (BOOL)saveObject:(MMCContainer *)object;  //储存

- (BOOL)removeObjectForId:(NSString *)id;   //去除指定ID的储存

- (NSInteger)count;    //储存数量

- (MMCContainer *)firstAdded;   //最先储存的（FIFO）

- (MMCContainer *)lastAdded;    //最近储存的

- (MMCContainer *)lastAccessed; //最近访问的

- (MMCContainer *)leastAccessed;    //最迟访问的（LRU）

- (MMCContainer *)mostAccessed; //最多访问的

- (MMCContainer *)leastRecentAccessed;  //最少访问的（LFU）

- (void)purify; //净化

- (NSArray <NSString *> *)allIds;   //分配内存


@end


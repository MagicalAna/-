//
//  MMCPolicyLRU.m
//  MMCache
//
//  Created by leon on 06/07/2018.
//  Copyright © 2018 leon. All rights reserved.
//

#import "MMCPolicyLRU.h"
#import "MMCContainer.h"
#import "MMCStorageProtocol.h"


@implementation MMCPolicyLRU


- (BOOL)saveObject:(MMCContainer *)object toStorage:(id<MMCStorageProtocol>)storage maxCapacity:(NSInteger)maxCapacity {
    if (maxCapacity > 0 && [storage count] >= maxCapacity) {
        if ([storage saveObject:object]){
            [storage removeObjectForId: object.id];
            MMCContainer *container = [storage leastAccessed];
            if (container.id) {
                if ([storage removeObjectForId:container.id]) {
                    NSLog(@"<LRU> FULL [%@ accessed at %@] was removed", container.object, container.accessTime);
                }
            } else {
                return [storage saveObject:object];
            }
        } else {
            return NO;
        }
    }
    return [storage saveObject:object];
}


@end

//
//  MMCache.m
//  MMCache
//
//  Created by leon on 06/07/2018.
//  Copyright © 2018 leon. All rights reserved.
//

#import "MMCache.h"
#import "MMCPolicyLFU.h"
#import "MMCPolicyLRU.h"
#import "MMCPolicyFIFO.h"
#import "MMCInMemoryStorage.h"
#import "MMCPersistentStorage.h"
#import "NSString+MD5.h"


@interface MMCache ()

@property (nonatomic, strong) id<MMCStorageProtocol> storage;
@property (nonatomic, strong) id<MMCPolicyProtocol> policy;

@end


@implementation MMCache


+ (MMCache *)sharedCache {
    static dispatch_once_t onceToken;
    static MMCache *_sharedCache;
    dispatch_once(&onceToken, ^{
        _sharedCache = MMCache.new;
    });
    return _sharedCache;
}


+ (MMCache *)cacheWithCapacity:(NSInteger)capacity policyType:(MMCPolicyType)policyType storageType:(MMCStorageType)storageType {
    MMCache *cache = MMCache.new;
    cache.storageType = storageType;
    cache.policyType = policyType;
    return cache;
}


- (void)setStorageType:(MMCStorageType)storageType {
    _storage = nil;
    switch (storageType) {
        case MMCStorageTypeInMemory: {
            //_storage = MMCInMemoryStorage.new;
            break;
        }
        case MMCStorageTypePersistent:{
            _storage = MMCPersistentStorage.new;
            break;
        }
        default: {
            [NSException raise:@"MMCStorageUndefined" format:@"storage type undefined"];
            break;
        }
    }
}


- (void)setPolicyType:(MMCPolicyType)policyType {
    switch (policyType) {
        case MMCPolicyTypeLRU: {
            _policy = MMCPolicyLRU.new;
            break;
        }
        case MMCPolicyTypeLFU: {
            _policy = MMCPolicyLFU.new;
            break;
        }
        case MMCPolicyTypeFIFO: {
            _policy = MMCPolicyFIFO.new;
            break;
        }
        default: {
            [NSException raise:@"MMCPolicyUndefined" format:@"cache policy type undefined"];
            break;
        }
    }
}


- (BOOL)saveObject:(id<NSCoding, NSObject>)object level:(MMCLevel)level name:(NSString *)name {
    MMCContainer *container = MMCContainer.add(object, level, 100);
    //container.id = [NSString stringWithFormat:@"%p", container].md5;
    container.id = name;
    return [self.policy saveObject:container toStorage:self.storage maxCapacity:self.capacity];
}


- (BOOL)saveObject:(id<NSCoding, NSObject>)object name:(NSString *)name {
    return [self saveObject:object level:MMCLevelDefault name:name];
}


- (id)objectForId:(NSString *)id {
    return [self.storage objectForId:id].object;
}


- (void)expireObjectForId:(NSString *)id {
    MMCContainer *container = [self.storage objectForId:id];
    container.duration = 0;
}


- (BOOL)removeObjectForId:(NSString *)id {
    return [self.storage removeObjectForId:id];
}


- (NSArray <NSString *> *)allIds {
    return self.storage.allIds;
}


- (NSInteger)size {
    return self.storage.count;
}


- (void)purify {
    [self.storage purify];
}

@end

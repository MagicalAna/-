//
//  Test.m
//  MMCache
//
//  Created by Yuan Ana on 2018/7/15.
//  Copyright © 2018 leon. All rights reserved.
//

#import "Test.h"

#define CACHE MMCache.sharedCache

@implementation Test

- (void)testGetDateTimeTOMilliSeconds {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    NSDate *date = [NSDate date];
    NSString *string = [a getDateTimeTOMilliSeconds: date];
    NSLog(@"%@", string);
}

- (void)testGetDateTimeFromMilliSeconds {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    NSDate *date = [NSDate date];
    NSString *string = [a getDateTimeTOMilliSeconds: date];
    NSDate *getDate = [a getDateTimeFromMilliSeconds: string];
    NSLog(@"%@", getDate);
}

- (void)testSaveObject {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    Dog *dog1 = [Dog dogWithName:@"billy" age:2 breed:@"Husky"];
    [CACHE saveObject:dog1];
    [a showTable];
}

- (void)testCountPlus: (char *)id {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    NSString *idInNSString = [NSString stringWithCString: id encoding:NSUTF8StringEncoding];
    [a countPlus: idInNSString];
    [a showTable];
}

- (void)testObjectForID: (char *)id {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    NSString *idInNSString = [NSString stringWithCString: id encoding:NSUTF8StringEncoding];
    [a objectForId: idInNSString];
    [a showTable];
}

- (void)testRemoveObjectForID: (char *)id {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    NSString *idInNSString = [NSString stringWithCString: id encoding:NSUTF8StringEncoding];
    [a removeObjectForId: idInNSString];
    [a showTable];
}

- (void)testAllIds {
    MMCPersistentStorage *a = MMCPersistentStorage.new;
    [a purify];
    Dog *dog1 = [Dog dogWithName:@"billy" age:2 breed:@"Husky"];
    [CACHE saveObject:dog1];
    Dog *dog2 = [Dog dogWithName:@"lucas" age:3 breed:@"Barbet"];
    [CACHE saveObject:dog2];
    [a showTable];
    NSLog(@"%@", [a allIds]);
}

@end

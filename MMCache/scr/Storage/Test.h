//
//  Test.h
//  MMCache
//
//  Created by Yuan Ana on 2018/7/15.
//  Copyright © 2018 leon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMCPersistentStorage.h"
#import "MMCache.h"
#import "Dog+NSCoding.h"

@interface Test : NSObject

- (void)testGetDateTimeTOMilliSeconds;

- (void)testGetDateTimeFromMilliSeconds;

- (void)testSaveObject;

- (void)testCountPlus: (char *)id;

- (void)testObjectForID: (char *)id;

- (void)testRemoveObjectForID: (char *)id;

- (void)testAllIds;

@end

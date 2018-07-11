//
//  Cat+NSCoding.m
//  MMCache
//
//  Created by Yuan Ana on 2018/7/8.
//  Copyright © 2018 leon. All rights reserved.
//

#import "Cat+NSCoding.h"
#import "Macro.h"

@implementation Cat (NSCoding)


- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:KEY(Cat, name)];
    [encoder encodeObject:self.breed forKey:KEY(Cat, breed)];
    [encoder encodeObject:self.favoriteFood forKey:KEY(Cat, favoriteFood)];
    [encoder encodeInteger:self.age forKey:KEY(Cat, age)];
}


- (id)initWithCoder:(NSCoder *)decoder {
    if(self = [super init]) {
        self.name         = [decoder decodeObjectForKey:KEY(Cat, name)];
        self.breed        = [decoder decodeObjectForKey:KEY(Cat, breed)];
        self.favoriteFood = [decoder decodeObjectForKey:KEY(Cat, favoriteFood)];
        self.age          = [decoder decodeIntegerForKey:KEY(Cat, age)];
    }
    return self;
}


@end

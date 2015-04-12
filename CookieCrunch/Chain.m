//
//  Chain.m
//  CookieCrunch
//
//  Created by shi qing on 15/4/8.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//


#import "Chain.h"

@implementation Chain {
    NSMutableArray *_cookies;
}

- (void)addCookie:(Cookie *)cookie {
    if (_cookies == nil) {
        _cookies = [NSMutableArray array];
    }
    
    [_cookies addObject:cookie];
}

- (NSArray *)cookies {
    return _cookies;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld cookies:%@", (long)self.chainType, self.cookies];
}

@end

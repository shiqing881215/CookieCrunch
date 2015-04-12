//
//  Chain.h
//  CookieCrunch
//
//  Created by shi qing on 15/4/8.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

/*
 Represent a chain of cookies
 */

#import <Foundation/Foundation.h>

@class Cookie;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
    // You can add more type, like T 
};

@interface Chain : NSObject

// Use NSArray here, but NSMutableArray in the implementation, so user cannot modify it (readonly)
@property (strong, nonatomic, readonly) NSArray *cookies;

@property (assign, nonatomic) ChainType chainType;

@property (assign, nonatomic) NSUInteger score;

- (void) addCookie:(Cookie *)cookie;

@end

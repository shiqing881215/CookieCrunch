//
//  Swap.h
//  CookieCrunch
//
//  Created by shi qing on 15/4/6.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

/*
 Another model class used to say "Cookie A wants to swap with Cookie B"
 */

#import <Foundation/Foundation.h>

@class Cookie;

@interface Swap : NSObject

@property (strong, nonatomic) Cookie *cookieA;
@property (strong, nonatomic) Cookie *cookieB;

@end

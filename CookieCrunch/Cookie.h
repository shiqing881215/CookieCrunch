//
//  Cookie.h
//  CookieCrunch
//
//  Created by shi qing on 15/4/1.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//



/*
 Model class represent the cookie
 
 {
 row
 column
 cookieType
 sprite
 }
 */


#import <Foundation/Foundation.h>

@import SpriteKit;

static const NSUInteger NumCookiesTypes = 6;

@interface Cookie : NSObject

// Position
@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSInteger column;
// Type
@property (assign, nonatomic) NSUInteger cookieType;
// View (use to display)
@property (assign, nonatomic) SKSpriteNode *sprite;

// returns the image file name of that sprite image in the texture atlas
- (NSString *) spriteName;
// return the highlight image file name
- (NSString *) highlightedSpriteName;

@end

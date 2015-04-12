//
//  Level.h
//  CookieCrunch
//
//  Created by shi qing on 15/4/3.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

/*
 Model class to hold all the cookie objects
 Main responsibility is to maintain the cookie data
 */

#import <Foundation/Foundation.h>
#import "Cookie.h"
#import "Tile.h"
#import "Swap.h"
#import "Chain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

// The 9*9 grid used to hold the cookie
@interface Level : NSObject

@property (assign, nonatomic) NSUInteger targetScore;
@property (assign, nonatomic) NSUInteger maximumMoves;

- (NSSet *) shuffle;

- (Cookie *) cookieAtColumn:(NSInteger)column row:(NSInteger)row;

- (instancetype) initWithFile:(NSString *) fileName;

- (Tile *) tileAtColumn:(NSInteger)column row:(NSInteger)row;

- (void) performSwap:(Swap *)swap;

- (void) detectPossibleSwaps;

- (BOOL) isPossibleSwap:(Swap *)swap;

- (NSSet *) removeMatches;

- (NSArray *) fillHoles;

- (NSArray *) topUpCookies;

@end

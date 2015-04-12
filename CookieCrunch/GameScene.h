//
//  GameScene.h
//  CookieCrunch
//

//  Copyright (c) 2015年 shi qing. All rights reserved.
//

/*
 View pare of the game.
 Need have a reference to Level to see all the data model.
 
 Main responsibilty :
 1. Add sprite for cookie / tile
 2. Detect all the action and send to ViewController
 3. Animate all the action
 */

#import <SpriteKit/SpriteKit.h>

@import SpriteKit;

@class Level;
@class Swap;

@interface GameScene : SKScene

@property (strong, nonatomic) Level *level;
// This is used as the block to send the meesage back to the view controller to do the real logic
@property (copy, nonatomic) void (^swapHandler)(Swap *swap);

- (void) addSpriteForCookies:(NSSet *)cookies;

- (void) addTiles;

- (void) animateSwap:(Swap *)swap completion:(dispatch_block_t)completion;

- (void) animateInvalidSwap:(Swap *)swap completion:(dispatch_block_t)completion;

- (void) animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion;

- (void) animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion;

- (void) animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion;

@end

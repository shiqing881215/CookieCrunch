//
//  GameScene.m
//  CookieCrunch
//
//  Created by shi qing on 15/3/30.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

/*
 GameLayer is the basic layer
 Both TilesLayer and CookiesLayer are the children of GameLayer
 TilesLayer and CookiesLayer are used to hold all the tile sprite and cookie sprite separately
 */

#import "GameScene.h"

#import "Cookie.h"
#import "Level.h"
#import "Swap.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface GameScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *cookiesLayer;
@property (strong, nonatomic) SKNode *tilesLayer;

@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

// This is for the selection highlight feature
@property (strong, nonatomic) SKSpriteNode *selectionSprite;

@end

@implementation GameScene

// This is called first instead of initWithSize after xCode 6
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        //TODO:  Need to figure out the right numbe here to make it fit the screen
        background.size = CGSizeMake(414, 736);
        [self addChild:background];
        
        // Add game layers
        self.gameLayer = [SKNode node];
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        
        // Add tile layer, need to be done first so that tiles show behind the cookie
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        self.cookiesLayer = [SKNode node];
        self.cookiesLayer.position = layerPosition;
        
        [self.gameLayer addChild:self.cookiesLayer];
        
        // Initialize with invalid values
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        // Initialize selectionSprite
        self.selectionSprite = [SKSpriteNode node];
    }
    
    return self;
}

// parameter cookies include all the cookie objects we created in the _cooikes
// this is to add the sprite to each of them so that they can display
- (void) addSpriteForCookies:(NSSet *)cookies {
    for (Cookie *cookie in cookies) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookiesLayer addChild:sprite];
        cookie.sprite = sprite;
    }
}

- (CGPoint) pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

// Add the sprite for the tile
- (void) addTiles {
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

/*
 * All the action detection should happen in the GameScene
 */
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Convert touch location to a point in the cookie layer
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column, row;
    // If in the 9*9 grid
    if ([self convertPoint:location toColumn:&column row:&row]) {
        // If have the cookie
        Cookie *cookie = [self.level cookieAtColumn:column row:row];
        if (cookie != nil) {
            self.swipeFromRow = row;
            self.swipeFromColumn = column;
            [self showSelectionIndicationForCookie:cookie];
        }
    }
}

// Whether this point is in the 9*9 grid
// and set the column and row value (which is the parameter passed in)
- (BOOL) convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    // First make sure column and row is not nil
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    if (point.x >= 0 && point.x < NumColumns*TileWidth &&
        point.y >= 0 && point.y < NumRows*TileHeight) {
        
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
        
    } else {
        *column = NSNotFound;  // invalid location
        *row = NSNotFound;
        return NO;
    }
}

// Actually we don't care about where does the touch ends
// we only care about where it starts and where it goes
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.swipeFromColumn == NSNotFound) return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    // Actually you are not allowed to swipe diagonal here
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {          // swipe left
            horzDelta = -1;
        } else if (column > self.swipeFromColumn) {   // swipe right
            horzDelta = 1;
        } else if (row < self.swipeFromRow) {         // swipe down
            vertDelta = -1;
        } else if (row > self.swipeFromRow) {         // swipe up
            vertDelta = 1;
        }
        
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            [self hideSelectionIndication];
        }
        
        // Reset
        self.swipeFromColumn = NSNotFound;
    }
}

// Do the real swap of two cookies
- (void) trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta {
    // The destination cookie to swap with
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    if (toColumn < 0 || toColumn >= NumColumns) return;
    if (toRow < 0 || toRow >= NumRows) return;
    
    Cookie *toCookie = [self.level cookieAtColumn:toColumn row:toRow];
    if (toCookie == nil) return;
    
    Cookie *fromCookie = [self.level cookieAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    // Do the swap
    Swap *swap = [[Swap alloc]init];
    swap.cookieA = fromCookie;
    swap.cookieB = toCookie;
    
    // This sends the message to the ViewController
    self.swapHandler(swap);
}

// This is called when ViewController decide this is a valid swap and wants to do the swap
- (void) animateSwap:(Swap *)swap completion:(dispatch_block_t)completion {
    // Put the start cookie on the top
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    // Use SKAction to do the action and animation
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.cookieB.sprite runAction:moveB];
}

- (void) animateInvalidSwap:(Swap *)swap completion:(dispatch_block_t)completion {
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    // First swap and then swap back immediately
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.cookieB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
}

// For completeness, we also need to implement the touchesEnd and touchesCancelled

// This happens when user lift their fingers
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.swipeFromRow = self.swipeFromColumn = NSNotFound;
    
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectionIndication];
    }
}

// This happens when ios need to cancell this touch like a phone call coming
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesCancelled:touches withEvent:event];
}

/*
 * For highlights indication
 */
 
// Show the highlights when select a cookie
- (void) showSelectionIndicationForCookie:(Cookie *)cookie {
    // If the selection indication is still visible, remove it first
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    // Get from the highlights image from cookie
    SKTexture *texture = [SKTexture textureWithImageNamed:[cookie highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    // Add to the cookie so it moves along with the cookie in the swap
    [cookie.sprite addChild:self.selectionSprite];
    // Make it visible
    self.selectionSprite.alpha = 1.0;
}

- (void) hideSelectionIndication {
    [self.selectionSprite runAction:[SKAction sequence:@[
        [SKAction fadeOutWithDuration:0.03],
        [SKAction removeFromParent]]]];
}

// Animate matched cookies go away
- (void) animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion {
    for (Chain *chain in chains) {
        for (Cookie *cookie in chain.cookies) {
            if (cookie.sprite != nil) {
                // First scale, then remove from parent, finally remove the sprite from cookie
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [cookie.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                cookie.sprite = nil;
            }
        }
    }
    
    [self runAction:[SKAction sequence:@[
        [SKAction waitForDuration:0.3],
        [SKAction runBlock:completion]
    ]]];
    
}

// Animate the cookies falling down to fill the holes
- (void) animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(Cookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
          
            NSTimeInterval delay = 0.05 + 0.15*idx;
            
            NSTimeInterval duration = ((cookie.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            longestDuration = MAX(longestDuration, duration + delay);
            
            // Do the move
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [cookie.sprite runAction:[SKAction sequence:@[
                [SKAction waitForDuration:delay],
                moveAction]]];
        }];
    }
    
    [self runAction:[SKAction sequence:@[
          [SKAction waitForDuration:longestDuration],
          [SKAction runBlock:completion]
    ]]];
}

// Animate add new cookies from top
- (void) animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        NSInteger startRow = ((Cookie *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(Cookie *cookie, NSUInteger idx, BOOL *stop) {
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
            sprite.position = [self pointForColumn:cookie.column row:startRow];
            [self.cookiesLayer addChild:sprite];
            cookie.sprite = sprite;

            NSTimeInterval delay = 0.1 + 0.2*([array count] - idx - 1);

            NSTimeInterval duration = (startRow - cookie.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 6
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            cookie.sprite.alpha = 0;
            [cookie.sprite runAction:[SKAction sequence:@[
             [SKAction waitForDuration:delay],
             [SKAction group:@[
              [SKAction fadeInWithDuration:0.05], moveAction]]]]];
        }];
    }
    
    // 7
    [self runAction:[SKAction sequence:@[
          [SKAction waitForDuration:longestDuration],
          [SKAction runBlock:completion]
    ]]];
}

@end

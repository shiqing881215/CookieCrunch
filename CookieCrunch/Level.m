//
//  Level.m
//  CookieCrunch
//
//  Created by shi qing on 15/4/3.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

#import "Level.h"

@interface Level()

// This is used to store all the possible swaps (you can also implement this logic during user swap)
// This will contain all the possible Swap objects
@property (strong, nonatomic) NSSet *possibleSwaps;

@end

// Include two two-dimensional array to hold cookie and tile objects in the 9*9 grid
@implementation Level {
    // TODO  Is the order here right ?  should be [row][col]??
    Cookie *_cookies[NumColumns][NumRows];
    
    Tile *_tiles[NumColumns][NumRows];
}

// If there is no possbile swap, then continue doing
- (NSSet *) shuffle {
    NSSet *set;
    do {
        set = [self createInitialCookies];
        
        [self detectPossibleSwaps];
        
        NSLog(@"possible swaps: %@", self.possibleSwaps);
    } while ([self.possibleSwaps count] == 0);
    
    return set;
}

// Initialize the _cookies and return a set with all created cookie objects
- (NSSet *) createInitialCookies {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger col = 0; col < NumColumns; col++) {
            if (_tiles[col][row] != nil) {
                // Create the cookie for this tile, keep in mind that in the start and end stage
                // we should not have any three continouse cookies in a row
                // So if we break the rule, continue do until we meet the rule
                NSUInteger cookieType;
                do {
                    cookieType = arc4random_uniform(NumCookiesTypes) + 1;
                } while ((col >= 2 &&
                          _cookies[col-1][row].cookieType == cookieType &&
                          _cookies[col-2][row].cookieType == cookieType)
                         ||
                         (row >= 2 &&
                          _cookies[col][row-1].cookieType == cookieType &&
                          _cookies[col][row-2].cookieType == cookieType));
                
                Cookie *cookie = [self createCookieAtColumn:col row:row withType:cookieType];
                [set addObject:cookie];
            }
        }
    }
    
    return set;
}

/*
 **************************** Swap Begin **********************************
 */

// Detect all the possible swap objects and store in the possibleSwaps private variable
- (void) detectPossibleSwaps {
    NSMutableSet *set = [NSMutableSet set];
    
    // From bottom up
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            Cookie *cookie = _cookies[column][row];
            if (cookie != nil) {
                // Check whether possible to swap the current cookie with the one on the right
                if (column < NumColumns-1) {
                    Cookie *other = _cookies[column+1][row];
                    if (other != nil) {
                        // swap
                        _cookies[column][row] = other;
                        _cookies[column+1][row] = cookie;
                        
                        // After swap if either of them belongs to a chain, add them
                        if ([self hasChainAtColumn:column row:row]
                            || [self hasChainAtColumn:column+1 row:row]) {
                            Swap *swap = [[Swap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        // swap back
                        _cookies[column][row] = cookie;
                        _cookies[column+1][row] = other;
                    }
                }
                
                // Check the top
                if (row < NumRows - 1) {
                    Cookie *other = _cookies[column][row + 1];
                    if (other != nil) {
                        // Swap them
                        _cookies[column][row] = other;
                        _cookies[column][row + 1] = cookie;
                        
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            Swap *swap = [[Swap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    // Update the possible swap set
    self.possibleSwaps = set;
}

// Detect a certain point whether has a chain(3 continuous same cookies) from four direction
- (BOOL) hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSInteger cookieType = _cookies[column][row].cookieType;
    
    NSInteger horzLength = 1;
    for (NSInteger i = column-1; i >= 0 && _cookies[i][row].cookieType == cookieType; i--, horzLength++);
    for (NSInteger i = column + 1; i < NumColumns && _cookies[i][row].cookieType == cookieType; i++, horzLength++) ;
    if (horzLength >= 3) return YES;
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1; i >= 0 && _cookies[column][i].cookieType == cookieType; i--, vertLength++) ;
    for (NSInteger i = row + 1; i < NumRows && _cookies[column][i].cookieType == cookieType; i++, vertLength++) ;
    return (vertLength >= 3);
}

- (BOOL) isPossibleSwap:(Swap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

/*
 **************************** Swap End **********************************
 */



- (Cookie *) cookieAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column : %ld", column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row : %ld", row);
    
    return _cookies[column][row];
}

- (Cookie *) createCookieAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSInteger)cookieType {
    Cookie *cookie = [[Cookie alloc] init];
    cookie.cookieType = cookieType;
    cookie.column = column;
    cookie.row = row;
    _cookies[column][row] = cookie;
    return cookie;
}

// Load the data from JSON file
- (NSDictionary *)loadJSON:(NSString *)fileName {
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find the file %@", fileName);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not load the file : %@ error : %@", fileName, error);
        return nil;
    }
    
    // JSON file is the key-value map, so use the NSDictionary here
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"File %@ is not a valid JSON file : %@", fileName, error);
        return nil;
    }
    
    return dictionary;
}

// Fill the _tiles based on the loaded JSON file
- (instancetype) initWithFile:(NSString *)fileName {
    self = [super init];
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:fileName];
        
        // Loop through rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            // Loop through the column in the current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If value is 1, create the tile object
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[Tile alloc] init];
                }
            }];
        }];
        
        self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
    }
    
    return self;
}

- (Tile *)tileAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

// Swap the cookies in the _cookies
- (void)performSwap:(Swap *)swap {
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;
}

/*
 *********************** Chain Begin ***************************
 */

// Detect all the horizontal matches and add them to the return set
- (NSSet *) detectHorizontalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns-2;) {
            if (_cookies[column][row] != nil) {
                // For the gap, cookieType is 0 - never match
                NSUInteger cookieType = _cookies[column][row].cookieType;
                
                if (_cookies[column+1][row].cookieType == cookieType &&
                    _cookies[column+2][row].cookieType == cookieType) {
                    Chain *chain = [[Chain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column++;
                    } while (column < NumColumns && _cookies[column][row].cookieType == cookieType);
                    // Add to set and continue
                    [set addObject:chain];
                    continue;
                }
            }
            column++;
        }
    }
    
    return set;
}

// Detect all the vertical matches and add them to the return set
- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row + 1].cookieType == matchType
                    && _cookies[column][row + 2].cookieType == matchType) {
                    
                    Chain *chain = [[Chain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row += 1;
                    }
                    while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    return set;
}

// We want both above two helper methods to detect all the horizontal and vertical chains
// instead of removing the chanin immediately when we find them, because a chain may belongs to
// two chains in horizontally and vertically
- (NSSet *) removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    // Combine two sets together
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

// Remove the cookies in the chain from the data model _cookies
- (void) removeCookies:(NSSet *)chains {
    for (Chain *chain in chains) {
        for (Cookie *cookie in chain.cookies) {
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}

/*
 *********************** Chain End ***************************
 */

// return an array containing all the cookies that have been moved down (falling), organized by column
// the return result will be used in the animateFallingCookies in the GameScene to animate falling
- (NSArray *) fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++) {
            // Find a hole
            if (_tiles[column][row] != nil && _cookies[column][row] == nil) {
                // find the nearest replacement cookie to fall in
                for (NSInteger lookup = row+1; lookup < NumRows; lookup++) {
                    Cookie *cookie = _cookies[column][lookup];
                    if (cookie != nil) {
                        // move to the hole
                        _cookies[column][lookup] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:cookie];
                        
                        // already find the nearest replacement for the hole, break
                        break;
                    }
                }
            }
        }
    }
    
    return columns;
}

// Fill in the new cookies when some chain disappears
// return is the all the new created cookies which is needed for the animation in the
// GameScene animateNewCookies
- (NSArray *) topUpCookies {
    NSMutableArray *columns = [NSMutableArray array];
    
    // Empty is 0
    NSUInteger cookieType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        for (NSInteger row = NumRows-1; row >= 0 && _cookies[column][row] == nil; row--) {
            if (_tiles[column][row] != nil) {
                NSUInteger newCookieType;
                do {
                    newCookieType = arc4random_uniform(NumCookiesTypes) + 1;
                } while (newCookieType == cookieType);
                cookieType = newCookieType;
                
                // Create the new cookie in this tile
                Cookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:cookie];
            }
        }
    }
    
    return columns;
}

// Update the chain score
- (void) calculateScores:(NSSet *)chains {
    for (Chain *chain in chains) {
        chain.score = 60 * ([chain.cookies count] - 2);
    }
}

@end

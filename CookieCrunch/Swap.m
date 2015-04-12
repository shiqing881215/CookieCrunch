//
//  Swap.m
//  CookieCrunch
//
//  Created by shi qing on 15/4/6.
//  Copyright (c) 2015年 shi qing. All rights reserved.
//

#import "Swap.h"
#import "Cookie.h"

@implementation Swap

// For debug
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

// Override the isEqual method cause we need to compare the Swap object in the possbileSwaps set
- (BOOL) isEqual:(id)object {
    if (![self isKindOfClass:[Swap class]]) return NO;
    
    Swap *other = (Swap *)object;
    return (other.cookieA == self.cookieA && other.cookieB == self.cookieB) ||
    (other.cookieB == self.cookieA && other.cookieA == self.cookieB);
}

- (NSUInteger) hash {
    return [self.cookieA hash] ^ [self.cookieB hash];
}

@end

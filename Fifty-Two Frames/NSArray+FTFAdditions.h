//
//  NSArray+FTFAdditions.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (FTFAdditions)

- (NSArray *)map:(id(^)(id object, NSUInteger index))block;
- (NSArray *)flattenedArray;

@end

@interface NSMutableArray (FTFAdditions)

- (void)flatten;

@end

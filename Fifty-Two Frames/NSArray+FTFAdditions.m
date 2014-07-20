//
//  NSArray+FTFAdditions.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "NSArray+FTFAdditions.h"

@implementation NSArray (FTFAdditions)

- (NSArray *)map:(id(^)(id object, NSUInteger index))block;
{
    NSParameterAssert(block);
    
    NSMutableArray *copy = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id i = block(obj, idx);
        if (i) {
            [copy addObject:i];
        }
    }];
    return [copy copy];
}

- (NSArray *)flattenedArray;
{
    NSMutableArray *flattened = [NSMutableArray new];
    for(id obj in self) {
        if([obj isKindOfClass:[NSArray class]]) {
            [flattened addObjectsFromArray:[obj flattenedArray]];
        } else {
            [flattened addObject:obj];
        }
    }
    return [flattened copy];
}

@end

@implementation NSMutableArray (FTFAdditions)

- (void)flatten;
{
    [self setArray:[self flattenedArray]];
}

@end
//
//  FTFCollectionViewCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFCollectionViewCell.h"

@implementation FTFCollectionViewCell

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [self layoutIfNeeded];
    [super applyLayoutAttributes:layoutAttributes];
}



@end

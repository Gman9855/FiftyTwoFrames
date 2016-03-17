//
//  FTFGridLayout.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 3/17/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFGridLayout.h"

@implementation FTFGridLayout

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    double itemWidth = [UIScreen mainScreen].bounds.size.width / 3 - 28;
    self.itemSize = CGSizeMake(itemWidth, itemWidth);
    self.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
    self.minimumInteritemSpacing = 8.0;
    self.minimumLineSpacing = 8.0;
}

- (void)prepareLayout {
    [super prepareLayout];
    [self setup];
}

@end

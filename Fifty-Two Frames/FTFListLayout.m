//
//  FTFListLayout.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 3/15/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFListLayout.h"

@implementation FTFListLayout

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    double width = [UIScreen mainScreen].bounds.size.width;
    self.itemSize = CGSizeMake(width, width + 27);
//    self.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
//    self.minimumInteritemSpacing = 8.0;
//    self.minimumLineSpacing = 8.0;
}

- (void)prepareLayout {
    [super prepareLayout];
    [self setup];
}

@end

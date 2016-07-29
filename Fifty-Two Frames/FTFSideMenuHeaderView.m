//
//  FTFSideMenuHeaderView.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/9/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFSideMenuHeaderView.h"

@interface FTFSideMenuHeaderView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineSeparatorHeightConstraint;

@end

@implementation FTFSideMenuHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 50.0;
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageView.layer.borderWidth = 3.0f;
    self.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.imageView.layer.shouldRasterize = YES;
    self.imageView.clipsToBounds = YES;
    self.lineSeparatorHeightConstraint.constant = 0.5;
}

- (void)updateImageViewSizeForContentOffset:(CGFloat)offset {
    self.imageViewHeightConstraint.constant = 100 - offset;
    self.imageView.layer.cornerRadius = self.imageViewHeightConstraint.constant / 2;
}

@end

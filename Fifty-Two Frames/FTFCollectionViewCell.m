//
//  FTFCollectionViewCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFCollectionViewCell.h"

@interface FTFCollectionViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewBottomToBottomDetailViewTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint *imageViewBottomToContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation FTFCollectionViewCell

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutDidChange:)
                                                     name:@"LayoutDidChange"
                                                   object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [self layoutIfNeeded];
    [super applyLayoutAttributes:layoutAttributes];
}

- (void)layoutDidChange:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"LayoutDidChange"]) {
        NSDictionary *userInfo = notification.userInfo;
        NSString *layoutType = (NSString*)userInfo[@"layoutType"];
        
        if ([layoutType isEqual:@"grid"]) {
            [self.bottomDetailView removeFromSuperview];
            [self.containerView removeConstraint:self.imageViewBottomToBottomDetailViewTopConstraint];
            self.imageViewBottomToContainerViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.thumbnailView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            [self addConstraint:self.imageViewBottomToContainerViewBottomConstraint];
        } else {
            [self.containerView addSubview:self.bottomDetailView];
            [self.containerView removeConstraint:self.imageViewBottomToContainerViewBottomConstraint];
            [self.containerView addConstraint:self.imageViewBottomToBottomDetailViewTopConstraint];
        }
        
        CGFloat time = [layoutType isEqual: @"grid"] ? 0 : 0.3;
        
        [UIView animateWithDuration:time delay:time options:0 animations:^{
            self.bottomDetailView.alpha = ![layoutType isEqual: @"grid"];
        } completion:nil];
    }
}

@end

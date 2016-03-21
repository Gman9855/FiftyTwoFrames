//
//  FTFCollectionViewCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFCollectionViewCell.h"

#import "CHTCollectionViewWaterfallLayout.h"

@interface FTFCollectionViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDetailViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDetailViewBottomToContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDetailViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDetailViewTrailingConstraint;

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
        NSString *layoutType = (NSString *)userInfo[@"layoutType"];
        UICollectionViewLayout *layout = (UICollectionViewLayout *)userInfo[@"layout"];
        
        [self updateCellsForLayout:layout];
        
        CGFloat time = [layoutType isEqual: @"grid"] ? 0 : 0.3;
        
        [UIView animateWithDuration:time delay:time options:0 animations:^{
            self.bottomDetailView.alpha = ![layoutType isEqual: @"grid"];
        } completion:nil];
    }
}

- (void)updateCellsForLayout:(UICollectionViewLayout *)layout {
    if ([layout isKindOfClass:[CHTCollectionViewWaterfallLayout class]]) {
        if ([self.containerView.subviews containsObject:self.bottomDetailView]) {
            [self.bottomDetailView removeFromSuperview];
            self.imageViewBottomToContainerViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.thumbnailView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            [self addConstraint:self.imageViewBottomToContainerViewBottomConstraint];
        }
        
    } else {
        if (![self.containerView.subviews containsObject:self.bottomDetailView]) {
            [self.containerView removeConstraint:self.imageViewBottomToContainerViewBottomConstraint];
            [self.containerView addSubview:self.bottomDetailView];
            [self.containerView addConstraint:self.bottomDetailViewHeightConstraint];
            [self.containerView addConstraint:self.bottomDetailViewLeadingConstraint];
            [self.containerView addConstraint:self.bottomDetailViewTrailingConstraint];
            [self.containerView addConstraint:self.bottomDetailViewBottomToContainerViewBottomConstraint];
            
            //FIXME:  Why the eff does this constraint not play nice?
            [self.containerView addConstraint:self.imageViewBottomToBottomDetailViewTopConstraint];
        }
    }
}

@end

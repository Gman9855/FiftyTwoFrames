//
//  FTFCollectionViewListCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 3/20/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFCollectionViewListCell.h"

@implementation FTFCollectionViewListCell

- (id)initWithFrame:(CGRect)aRect {
    if ((self = [super initWithFrame:aRect])) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutDidChange:)
                                                     name:@"LayoutDidChange"
                                                   object:nil];
        
    }
    return self;
}

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
        NSLog(@"%@", layoutType);
        CGFloat time = [layoutType isEqual: @"grid"] ? 0 : 0.3;        
        
        [UIView animateWithDuration:time delay:time options:0 animations:^{
            self.bottomDetailView.alpha = ![layoutType isEqual: @"grid"];
        } completion:nil];
    }
}

@end

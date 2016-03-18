//
//  FTFCollectionViewCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFCollectionViewCell.h"

@implementation FTFCollectionViewCell

- (void)commonInit
{
    // do any initialization that's common to both -initWithFrame:
    // and -initWithCoder: in this method
}

- (id)initWithFrame:(CGRect)aRect {
    if ((self = [super initWithFrame:aRect])) {
        [self commonInit];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutDidChange:)
                                                     name:@"LayoutDidChange"
                                                   object:nil];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        [self commonInit];
        
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

- (void) layoutDidChange:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"LayoutDidChange"]) {
        NSDictionary* userInfo = notification.userInfo;
        NSString* layoutType = (NSString*)userInfo[@"layoutType"];
        
        // Can use switch statement, but only works with a string in Swift, otherwise you have to use a dictrionary
        if ([layoutType  isEqual: @"grid"]) {
            self.bottomDetailView.hidden = YES;
        } else {
            self.bottomDetailView.hidden = NO;
        }
    }
        
}



@end

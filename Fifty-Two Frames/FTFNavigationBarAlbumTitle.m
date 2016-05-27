//
//  FTFNavigationBarAlbumTitle.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 4/18/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFNavigationBarAlbumTitle.h"

@implementation FTFNavigationBarAlbumTitle

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super initWithFrame:CGRectMake(0, 0, 200, 85)]) {
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = [UIColor whiteColor];
        self.font = [UIFont fontWithName:@"Lato-Regular" size:14];
        self.numberOfLines = 2;
        
        [self setAttributedTitleWithText:title];
    }
    
    return self;
}

- (void)setAttributedTitleWithText:(NSString *)title {
    NSMutableAttributedString *attributedString;
    if ([title containsString:@":"]) {
        attributedString = [[NSMutableAttributedString alloc]initWithString:title];
        NSArray *words = [title componentsSeparatedByString:@": "];
        NSString *albumName = [words firstObject];
        NSRange range = [title rangeOfString:albumName];
        range.length++;
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
        [self setAttributedText:attributedString];
    } else if ([title isEqualToString:@"52Frames"]) {
        attributedString = [[NSMutableAttributedString alloc]initWithString:title];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:NSMakeRange(0,2)];
        [self setAttributedText:attributedString];
    } else {
        self.text = title;
    }
}

@end

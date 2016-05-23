//
//  FTFFocalLengthRangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFFocalLengthRangeSlider.h"

@implementation FTFFocalLengthRangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.maximumValue = 300;
    self.minimumValue = 8;
    [self resetKnobs];
    self.stepValue = 1.0;
    self.stepValueContinuously = YES;

    self.tintColor = [UIColor orangeColor];
}

- (NSString *)upperValueFocalLength {
    return [NSString stringWithFormat:@"%dmm", (int)self.upperValue];
}

- (NSString *)lowerValueFocalLength {
    return [NSString stringWithFormat:@"%dmm", (int)self.lowerValue];
}

- (void)resetKnobs {
    self.upperValue = 300;
    self.lowerValue = 8;
}

@end

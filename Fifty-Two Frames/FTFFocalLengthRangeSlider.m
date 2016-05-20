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
    self.upperValue = 300;  // this sets the position of the knob
    self.lowerValue = 8;
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

@end

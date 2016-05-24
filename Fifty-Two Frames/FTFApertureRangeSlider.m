//
//  FTFApertureRangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFApertureRangeSlider.h"

@implementation FTFApertureRangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.maximumValue = 10;
    self.minimumValue = 1;
    [self resetKnobs];
    self.stepValue = 1.0;
    self.stepValueContinuously = YES;
    self.tintColor = [UIColor orangeColor];
}

- (double)upperValueAperture {
    return [self.apertureValueMapping[[NSNumber numberWithFloat:self.upperValue]] doubleValue];
}

- (double)lowerValueAperture {
    return [self.apertureValueMapping[[NSNumber numberWithFloat:self.lowerValue]] doubleValue];
}

- (NSString *)upperValueApertureString {
    return self.apertureValueStringMapping[[NSNumber numberWithFloat:self.upperValue]];
}

- (NSString *)lowerValueApertureString {
    return self.apertureValueStringMapping[[NSNumber numberWithFloat:self.lowerValue]];
}

- (NSDictionary *)apertureValueMapping {
    return @{@1 : [NSNumber numberWithDouble:1.4],
             @2 : [NSNumber numberWithDouble:1.8],
             @3 : [NSNumber numberWithDouble:2.8],
             @4 : [NSNumber numberWithDouble:3.5],
             @5 : [NSNumber numberWithDouble:4.0],
             @6 : [NSNumber numberWithDouble:5.6],
             @7 : [NSNumber numberWithDouble:8],
             @8 : [NSNumber numberWithDouble:11],
             @9 : [NSNumber numberWithDouble:16],
            @10 : [NSNumber numberWithDouble:22]
            };
}

- (NSDictionary *)apertureValueStringMapping {
    return @{@1 : @"f/1.4",
             @2 : @"f/1.8",
             @3 : @"f/2.8",
             @4 : @"f/3.5",
             @5 : @"f/4.0",
             @6 : @"f/5.6",
             @7 : @"f/8",
             @8 : @"f/11",
             @9 : @"f/16",
             @10 : @"f/22+"
             };
}

- (void)resetKnobs {
    self.upperValue = 10;
    self.lowerValue = 1;
}

@end

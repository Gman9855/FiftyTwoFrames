//
//  FTFShutterSpeedRangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/24/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFShutterSpeedRangeSlider.h"

@implementation FTFShutterSpeedRangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.maximumValue = 11;
    self.minimumValue = 1;
    [self resetKnobs];
    self.stepValue = 1.0;
    self.stepValueContinuously = YES;
    
    self.tintColor = [UIColor orangeColor];
}

- (NSString *)upperValueShutterSpeedString {
    return self.shutterSpeedStringValueMapping[[NSNumber numberWithFloat:self.upperValue]];
}

- (NSString *)lowerValueShutterSpeedString {
    return self.shutterSpeedStringValueMapping[[NSNumber numberWithFloat:self.lowerValue]];
}

- (double)lowerValueShutterSpeed {
    return [self.shutterSpeedValueMapping[[NSNumber numberWithFloat:self.lowerValue]] doubleValue];
}

- (double)upperValueShutterSpeed {
    return [self.shutterSpeedValueMapping[[NSNumber numberWithFloat:self.upperValue]] doubleValue];

}

- (NSDictionary *)shutterSpeedValueMapping {
    return @{@1 : [NSNumber numberWithDouble:(double)1 / 2000],
             @2 : [NSNumber numberWithDouble:(double)1 / 500],
             @3 : [NSNumber numberWithDouble:(double)1 / 250],
             @4 : [NSNumber numberWithDouble:(double)1 / 125],
             @5 : [NSNumber numberWithDouble:(double)1 / 60],
             @6 : [NSNumber numberWithDouble:(double)1 / 30],
             @7 : [NSNumber numberWithDouble:(double)1 / 15],
             @8 : [NSNumber numberWithDouble:(double)1 / 8],
             @9 : [NSNumber numberWithDouble:(double)1 / 4],
            @10 : [NSNumber numberWithDouble:(double)1 / 2],
            @11 : [NSNumber numberWithDouble:1]
            };
}

- (NSDictionary *)shutterSpeedStringValueMapping {
    return @{@1 : @"1/2000th",
             @2 : @"1/500th",
             @3 : @"1/250th",
             @4 : @"1/125th",
             @5 : @"1/60th",
             @6 : @"1/30th",
             @7 : @"1/15th",
             @8 : @"1/8th",
             @9 : @"1/4th",
             @10 : @"1/2nd",
             @11 : @"1 Second+"
             };
}

- (void)resetKnobs {
    self.upperValue = 11;
    self.lowerValue = 1;
}

@end

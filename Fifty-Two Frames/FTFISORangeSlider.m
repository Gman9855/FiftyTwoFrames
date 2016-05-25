//
//  FTFISORangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/24/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFISORangeSlider.h"

@implementation FTFISORangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.maximumValue = 6;
    self.minimumValue = 1;
    [self resetKnobs];
    self.stepValue = 1.0;
    self.stepValueContinuously = YES;
    
    self.tintColor = [UIColor orangeColor];
}

- (NSString *)upperValueISOString {
    return self.ISOStringValueMapping[[NSNumber numberWithFloat:self.upperValue]];
}

- (NSString *)lowerValueISOString {
    return self.ISOStringValueMapping[[NSNumber numberWithFloat:self.lowerValue]];
}

- (NSInteger)lowerValueISO {
    return [self.ISOValueMapping[[NSNumber numberWithFloat:self.lowerValue]] integerValue];
}

- (NSInteger)upperValueISO {
    return [self.ISOValueMapping[[NSNumber numberWithFloat:self.upperValue]] integerValue];
    
}

- (NSDictionary *)ISOValueMapping {
    return @{@1 : [NSNumber numberWithInteger:100],
             @2 : [NSNumber numberWithInteger:200],
             @3 : [NSNumber numberWithInteger:400],
             @4 : [NSNumber numberWithInteger:800],
             @5 : [NSNumber numberWithInteger:1600],
             @6 : [NSNumber numberWithInteger:3200]
             };
}

- (NSDictionary *)ISOStringValueMapping {
    return @{@1 : @"100 and below",
             @2 : @"200",
             @3 : @"400",
             @4 : @"800",
             @5 : @"1600",
             @6 : @"3200+"
             };
}

- (void)resetKnobs {
    self.upperValue = 11;
    self.lowerValue = 1;
}

@end

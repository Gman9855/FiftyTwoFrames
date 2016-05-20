//
//  FTFApertureRangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFApertureRangeSlider.h"

@interface FTFApertureRangeSlider ()

@property (nonatomic, strong) NSDictionary *apertureValueMapping;

@end

@implementation FTFApertureRangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.maximumValue = 10;
    self.minimumValue = 1;
    self.upperValue = 10;  // this sets the position of the knob
    self.lowerValue = 1;
    self.stepValue = 1.0;
    self.stepValueContinuously = YES;
    self.tintColor = [UIColor orangeColor];
}

- (NSString *)upperValueAperture {
    return self.apertureValueMapping[[NSNumber numberWithFloat:self.upperValue]];
}

- (NSString *)lowerValueAperture {
    return self.apertureValueMapping[[NSNumber numberWithFloat:self.lowerValue]];
}

- (NSDictionary *)apertureValueMapping {
    if (!_apertureValueMapping) {
        _apertureValueMapping = @{@1 : @"f/1.4",
                                  @2 : @"f/1.8",
                                  @3 : @"f/2.8",
                                  @4 : @"f/3.5",
                                  @5 : @"f/4",
                                  @6 : @"f/5.6",
                                  @7 : @"f/8",
                                  @8 : @"f/11",
                                  @9 : @"f/16",
                                  @10 : @"f/22+"
                                  };
    }
    
    return  _apertureValueMapping;
}

@end

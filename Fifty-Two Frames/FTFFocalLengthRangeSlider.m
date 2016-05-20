//
//  FTFFocalLengthRangeSlider.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFFocalLengthRangeSlider.h"

@interface FTFFocalLengthRangeSlider ()

@property (nonatomic, strong) NSDictionary *focalLengthValueMapping;

@end

@implementation FTFFocalLengthRangeSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    self.minimumValue = 8;  // this sets the position of the knob
    self.maximumValue = 300;
    self.lowerValue = 8;
    self.upperValue = 300;
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

- (NSDictionary *)focalLengthValueMapping {
    if (!_focalLengthValueMapping) {
        _focalLengthValueMapping = @{@1 : @"f/1.4",
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
    
    return  _focalLengthValueMapping;
}

- (NSString *)apertureValueForLowerKnobValue {
    return self.focalLengthValueMapping[[NSNumber numberWithFloat:self.lowerValue]];
}

@end

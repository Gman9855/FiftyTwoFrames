//
//  FTFApertureRangeSlider.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <NMRangeSlider/NMRangeSlider.h>

@interface FTFApertureRangeSlider : NMRangeSlider

@property (nonatomic, assign) double upperValueAperture;
@property (nonatomic, assign) double lowerValueAperture;
@property (nonatomic, strong) NSString *upperValueApertureString;
@property (nonatomic, strong) NSString *lowerValueApertureString;

- (void)resetKnobs;

@end

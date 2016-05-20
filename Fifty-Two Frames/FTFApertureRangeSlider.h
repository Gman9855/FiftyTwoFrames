//
//  FTFApertureRangeSlider.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <NMRangeSlider/NMRangeSlider.h>

@interface FTFApertureRangeSlider : NMRangeSlider

@property (nonatomic, strong) NSString *upperValueAperture;
@property (nonatomic, strong) NSString *lowerValueAperture;

@end

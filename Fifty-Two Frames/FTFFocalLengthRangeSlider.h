//
//  FTFFocalLengthRangeSlider.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/19/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <NMRangeSlider/NMRangeSlider.h>

@interface FTFFocalLengthRangeSlider : NMRangeSlider

@property (nonatomic, strong) NSString *upperValueFocalLength;
@property (nonatomic, strong) NSString *lowerValueFocalLength;

@end

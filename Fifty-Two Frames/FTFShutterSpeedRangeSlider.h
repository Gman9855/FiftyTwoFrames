//
//  FTFShutterSpeedRangeSlider.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/24/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <NMRangeSlider/NMRangeSlider.h>

@interface FTFShutterSpeedRangeSlider : NMRangeSlider

@property (nonatomic, assign) double upperValueShutterSpeed;
@property (nonatomic, assign) double lowerValueShutterSpeed;
@property (nonatomic, strong) NSString *upperValueShutterSpeedString;
@property (nonatomic, strong) NSString *lowerValueShutterSpeedString;

- (void)resetKnobs;

@end

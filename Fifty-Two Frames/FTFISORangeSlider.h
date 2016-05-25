//
//  FTFISORangeSlider.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/24/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <NMRangeSlider/NMRangeSlider.h>

@interface FTFISORangeSlider : NMRangeSlider

@property (nonatomic, assign) NSInteger upperValueISO;
@property (nonatomic, assign) NSInteger lowerValueISO;
@property (nonatomic, strong) NSString *upperValueISOString;
@property (nonatomic, strong) NSString *lowerValueISOString;

- (void)resetKnobs;

@end

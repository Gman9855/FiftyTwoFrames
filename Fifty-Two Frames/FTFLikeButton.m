//
//  FTFLikeButton.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 12/11/15.
//  Copyright © 2015 Gershy Lev. All rights reserved.
//

#import "FTFLikeButton.h"

@implementation FTFLikeButton

- (void)animateTap {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.2;
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    anim.removedOnCompletion = YES;
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)];
    [self.layer addAnimation:anim forKey:nil];
}

@end

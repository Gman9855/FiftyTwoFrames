//
//  FTFPhotoViewController.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTFImage.h"

@interface FTFPhotoViewController : UIViewController

@property (nonatomic, strong) FTFImage *photo;
@property (nonatomic, assign) NSInteger photoCount;

@end

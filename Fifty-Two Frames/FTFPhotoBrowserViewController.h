//
//  FTFPhotoBrowserViewController.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/7/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "MWPhotoBrowser.h"

@interface FTFPhotoBrowserViewController : MWPhotoBrowser

@property (nonatomic, assign) NSInteger selectedPhotoIndex;
@property (nonatomic, strong) NSArray *albumPhotos;
@property (nonatomic, strong) NSArray *browserPhotos;

@end

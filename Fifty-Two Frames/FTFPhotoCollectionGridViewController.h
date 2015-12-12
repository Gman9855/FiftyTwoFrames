//
//  FTFPhotoCollectionViewController.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FTFPhotoCollectionGridViewControllerDelegate <NSObject>

- (void)photoCollectionGridDidSelectPhotoAtIndex:(NSInteger)index;

@end

@interface FTFPhotoCollectionGridViewController : UICollectionViewController

@property (nonatomic, weak) id <FTFPhotoCollectionGridViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray *gridPhotos;
@property (nonatomic, strong) NSString *albumName;

@end

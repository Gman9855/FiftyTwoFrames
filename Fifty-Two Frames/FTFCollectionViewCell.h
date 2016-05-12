//
//  FTFCollectionViewCell.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FTFLikeButton;

@interface FTFCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UIView *bottomDetailView;
@property (weak, nonatomic) IBOutlet UILabel *photographerName;
@property (weak, nonatomic) IBOutlet UILabel *photoLikeCount;

@property (strong, nonatomic) NSLayoutConstraint *imageViewBottomToContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewBottomToBottomDetailViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet FTFLikeButton *likeButton;

- (void)updateCellsForLayout:(UICollectionViewLayout *)layout;

@end

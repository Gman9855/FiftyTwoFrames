//
//  FTFCollectionViewCell.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTFCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UIView *bottomDetailView;

@property (strong, nonatomic) NSLayoutConstraint *imageViewBottomToContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewBottomToBottomDetailViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (void)updateCellsForLayout:(UICollectionViewLayout *)layout;

@end

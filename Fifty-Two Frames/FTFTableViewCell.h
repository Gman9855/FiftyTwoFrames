//
//  FTFTableViewCell.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/4/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FTFImage;

@interface FTFTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UILabel *photographerLabel;
//@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@end

//
//  FTFTableViewCell.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/4/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFTableViewCell.h"
#import "FTFImage.h"

@implementation FTFTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)configureWithPhoto:(FTFImage *)photo {
    if (![photo.photoComments isEqual:[NSNull null]]) {
        self.commentsCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[photo.photoComments count]];
    }
    
    self.likesCountLabel.text = [NSString stringWithFormat:@"%ld", (long)photo.photoLikesCount];
    
    if (![photo.photoDescription isEqual:[NSNull null]]) {
        self.descriptionLabel.text = photo.photoDescription;
    } else {
        self.descriptionLabel.text = @"";
    }
    
    NSLog(@"%hhd", photo.isLiked);
    [self.likeButton setImage:[UIImage imageNamed:photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"] forState:UIControlStateNormal];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

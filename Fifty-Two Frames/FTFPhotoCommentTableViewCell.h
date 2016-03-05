//
//  FTFPhotoCommentTableViewCell.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/8/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTFPhotoCommentTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *commenterName;
@property (weak, nonatomic) IBOutlet UIImageView *commenterProfilePicture;
@property (weak, nonatomic) IBOutlet UILabel *commentDate;
@property (weak, nonatomic) IBOutlet UILabel *commentBody;

@end

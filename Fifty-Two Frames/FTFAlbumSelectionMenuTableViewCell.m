//
//  FTFAlbumSelectionMenuTableViewCell.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/8/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbumSelectionMenuTableViewCell.h"

@implementation FTFAlbumSelectionMenuTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

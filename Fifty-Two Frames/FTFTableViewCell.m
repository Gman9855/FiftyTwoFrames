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

- (void)prepareForReuse;
{
    [super prepareForReuse];
    
//    self.photo.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

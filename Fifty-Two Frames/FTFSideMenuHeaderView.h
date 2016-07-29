//
//  FTFSideMenuHeaderView.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/9/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTFSideMenuHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

- (void)updateImageViewSizeForContentOffset:(CGFloat)offset;

@end

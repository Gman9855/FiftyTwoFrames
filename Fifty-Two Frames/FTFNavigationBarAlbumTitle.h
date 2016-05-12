//
//  FTFNavigationBarAlbumTitle.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 4/18/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTFNavigationBarAlbumTitle : UILabel

- (instancetype)initWithTitle:(NSString *)title;

- (void)setAttributedTitleWithText:(NSString *)title;

@end

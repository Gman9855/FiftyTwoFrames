//
//  FTFContentTableViewController.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/2/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class FTFImage;

@interface FTFContentTableViewController : UITableViewController

- (void)scrollToPhoto:(FTFImage *)photo;

@end

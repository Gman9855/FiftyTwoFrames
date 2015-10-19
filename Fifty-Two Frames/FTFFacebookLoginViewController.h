//
//  FTFFacebookLoginViewController.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/5/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FTFFacebookLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet FBSDKLoginButton *loginButton;

@end

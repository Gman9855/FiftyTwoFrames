//
//  FTFFacebookLoginViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/5/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFFacebookLoginViewController.h"
#import "FTFAppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "FiftyTwoFrames.h"
#import <Parse/Parse.h>
#import "FTFUser.h"

@interface FTFFacebookLoginViewController ()

@end

@implementation FTFFacebookLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loginButton.readPermissions = @[@"public_profile", @"user_friends"];
    self.loginButton.publishPermissions =  @[@"publish_actions"];
//    self.loginButton.center = self.view.center;
//    [self.view addSubview:self.loginButton];
//    self.loginButton.alpha = 0.0;
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
//    CGFloat endY = self.loginButton.frame.origin.y;
//    CGRect buttonStartingPosition = self.loginButton.frame;
//    buttonStartingPosition.origin.y = self.view.bounds.size.height;
//    self.loginButton.frame = buttonStartingPosition;
//    CGRect endView = self.loginButton.frame;
//    endView.origin.y = endY;
//    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        self.loginButton.alpha = 1.0;
//        self.loginButton.frame = endView;
//
//    } completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

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
    self.loginButton.readPermissions =
    @[@"public_profile", @"email", @"user_friends"];
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

//- (void)requestUserPermissions;
//{
//    NSArray *permissionsNeeded = @[@"basic_info", @"user_photos"];
//    
//    // Request the permissions the user currently has
//    [FBRequestConnection startWithGraphPath:@"/me/permissions"
//                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                              if (!error){
//                                  // These are the current permissions the user has:
//                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
//                                  
//                                  // We will store here the missing permissions that we will have to request
//                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
//                                  
//                                  // Check if all the permissions we need are present in the user's current permissions
//                                  // If they are not present add them to the permissions to be requested
//                                  for (NSString *permission in permissionsNeeded){
//                                      if (![currentPermissions objectForKey:permission]){
//                                          [requestPermissions addObject:permission];
//                                      }
//                                  }
//                                  
//                                  // If we have permissions to request
//                                  if ([requestPermissions count] > 0){
//                                      // Ask for the missing permissions
//                                      [FBSession.activeSession
//                                       requestNewReadPermissions:requestPermissions
//                                       completionHandler:^(FBSession *session, NSError *error) {
//                                           if (!error) {
//                                               // Permission granted
//                                               NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
//                                               // We can request the user information
//                                               [self makeRequestForUserData];
//                                           } else {
//                                               // An error occurred, we need to handle the error
//                                               // See: https://developers.facebook.com/docs/ios/errors
//                                           }
//                                       }];
//                                  } else {
//                                      // Permissions are present
//                                      // We can request the user information
//                                      [self makeRequestForUserData];
//                                  }
//                                  
//                              } else {
//                                  // An error occurred, we need to handle the error
//                                  // See: https://developers.facebook.com/docs/ios/errors
//                              }
//                          }];
//}

//- (void)makeRequestForUserData;
//{
//    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if (!error) {
//            // Success! Include your code to handle the results here
//            NSLog(@"user info: %@", result);
//        } else {
//            // An error occurred, we need to handle the error
//            // See: https://developers.facebook.com/docs/ios/errors
//        }
//    }];
//}

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

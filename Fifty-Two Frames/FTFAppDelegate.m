//
//  FTFAppDelegate.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/1/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAppDelegate.h"
#import "FTFContainerViewController.h"

@interface FTFAppDelegate ()

@property (nonatomic, strong) FTFContainerViewController *containerViewController;

@end

@implementation FTFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    [@[@"foo", @"bar", @"baz", @"faz"] map:^id(id object, NSUInteger index) {
        NSLog(@"object: %@, index %u", object, index);
        return object;
    }];

    // Override point for customization after application launch.
    [FBLoginView class];
    
    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_photos"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          // also for intermediate states and NOT just when the session open
                                          [self sessionStateChanged:session state:state error:error];
                                      }];
        
        NSArray *permissions = [[FBSession activeSession] permissions];
        if (![permissions containsObject:@"publish_actions"]) {
            [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                                  defaultAudience:FBSessionDefaultAudienceEveryone
                                                completionHandler:^(FBSession *session, NSError *error) {
                                                    __block NSString *alertText;
                                                    __block NSString *alertTitle;
                                                    if (!error) {
                                                        if ([FBSession.activeSession.permissions
                                                             indexOfObject:@"publish_actions"] == NSNotFound){
                                                            // Permission not granted, tell the user we will not publish
                                                            alertTitle = @"Permission not granted";
                                                            alertText = @"Your action will not be published to Facebook.";
                                                            [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                        message:alertText
                                                                                       delegate:self
                                                                              cancelButtonTitle:@"OK!"
                                                                              otherButtonTitles:nil] show];
                                                        } else {
                                                            // Permission granted, publish the OG story
                                                        }
                                                        
                                                    } else {
                                                        // There was an error, handle it
                                                        // See https://developers.facebook.com/docs/ios/errors/
                                                    }
                                                }];
        }
    };
    return YES;
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    // customize your code...
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    
    return wasHandled;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

//
//  FTFAppDelegate.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/1/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAppDelegate.h"
#import <Parse/Parse.h>
#import "FTFContainerViewController.h"
#import "FTFContentTableViewController.h"
#import "FTFAlbumSelectionMenuViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginButton.h>
#import "UIWindow+UIWindow_Additions.h"

@interface FTFAppDelegate ()

@property (nonatomic, strong) FTFContainerViewController *containerViewController;

@end

@implementation FTFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"XXG1mhiISVKufte798cl8ScMYYkq2YXEc8HBkR5p"
                  clientKey:@"s6zCQa7DzB4hQKWaaNqdfsdt4YELOWqfuMqZWvNE"];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    [FBSDKLoginButton class];
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
    ];
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
    if (application.applicationIconBadgeNumber > 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FTFContainerViewController *containerVC = (FTFContainerViewController *)[storyboard instantiateViewControllerWithIdentifier:@"containerVC"];
        self.window.rootViewController = containerVC;
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
        }
    }
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [PFPush handlePush:userInfo];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FTFContainerViewController *containerVC = (FTFContainerViewController *)[storyboard instantiateViewControllerWithIdentifier:@"containerVC"];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        //present alert view
        NSString *alert = [userInfo valueForKeyPath:@"aps.alert"];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"52Frames" message:alert preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshAlbumCollection" object:nil];
        }];
        UIAlertAction *view = [UIAlertAction actionWithTitle:@"View" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            self.window.rootViewController = containerVC;
        }];
        
        [alertController addAction:dismiss];
        [alertController addAction:view];

        
        UIViewController *topVC = [self.window visibleViewController];
        [topVC presentViewController:alertController animated:YES completion:nil];
    } else {
        self.window.rootViewController = containerVC;
    }
}

@end

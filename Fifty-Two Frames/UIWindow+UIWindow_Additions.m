//
//  UIWindow+UIWindow_Additions.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 10/25/15.
//  Copyright © 2015 Gershy Lev. All rights reserved.
//

#import "UIWindow+UIWindow_Additions.h"

@implementation UIWindow (UIWindow_Additions)

- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

@end

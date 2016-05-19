//
//  FTFContainerViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/8/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFContainerViewController.h"
#import "FTFFacebookLoginViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface FTFContainerViewController ()

@property (strong, nonatomic) UIViewController *contentViewController;
@property (strong, nonatomic) UIViewController *facebookLoginViewController;
@property (strong, nonatomic) UIViewController *currentViewController;

@end

@implementation FTFContainerViewController

- (UIViewController *)contentViewController {
    if (!_contentViewController) {
        _contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"collectionViewNavController"];
    }
    return _contentViewController;
}

- (UIViewController *)facebookLoginViewController {
    if (!_facebookLoginViewController) {
        _facebookLoginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"facebookLoginView"];
    }
    return _facebookLoginViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChildViewControllerFromLoginState) name:FBSDKAccessTokenDidChangeNotification object:nil];
    [self updateChildViewControllerFromLoginState];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if ([FBSDKAccessToken currentAccessToken]) {
//            [[FBSDKLoginManager new] logOut];
//        }
//    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)viewControllerFromLoginState;
{
    if ([FBSDKAccessToken currentAccessToken]) {
        return self.contentViewController;
    }
    
    return self.facebookLoginViewController;
}

- (void)updateChildViewControllerFromLoginState;
{
    UIViewController *newViewController = [self viewControllerFromLoginState];
    if (![newViewController isEqual:self.currentViewController]) {
        [self addChildViewController:newViewController];
        newViewController.view.frame = self.view.bounds;
        
        if (self.currentViewController) {
            [self transitionFromViewController:self.currentViewController
                              toViewController:newViewController
                                      duration:1.2
                                       options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight
                                    animations:^{
                                        [self.currentViewController removeFromParentViewController];
                                    } completion:^(BOOL finished) {
                                        self.currentViewController = newViewController;
                                    }];
        } else {
            self.currentViewController = newViewController;
            [self.view addSubview:newViewController.view];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if ([keyPath isEqualToString:@"state"]) {
        [self updateChildViewControllerFromLoginState];
    }
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

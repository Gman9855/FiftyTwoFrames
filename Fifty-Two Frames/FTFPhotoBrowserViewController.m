//
//  FTFPhotoBrowserViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/7/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoBrowserViewController.h"
#import "FTFImage.h"
#import "WYPopoverController.h"
#import "FTFPhotoCommentsViewController.h"
#import "FiftyTwoFrames.h"
#import <FacebookSDK/FacebookSDK.h>

NSString *const didPressLikeNotification = @"didPressLikeNotification";

@interface FTFPhotoBrowserViewController () <FTFPhotoCommentsViewControllerDelegate>

@property (nonatomic, strong) WYPopoverController *photoCommentsPopoverController;
@property (nonatomic, strong) UINavigationController *photoCommentsNavigationController;
@property (nonatomic, strong) UIView *hostingViewForCommentView;
@property (nonatomic, strong) UIImageView *imageViewForButton;
@property (nonatomic, strong) UILabel *navigationBarLabel;

@end

@implementation FTFPhotoBrowserViewController

- (UINavigationController *)photoCommentsNavigationController {
    if (!_photoCommentsNavigationController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _photoCommentsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"photoCommentsNavigationController"];
    }
    return _photoCommentsNavigationController;
}

- (FTFPhotoCommentsViewController *)photoCommentsVC {
    return (FTFPhotoCommentsViewController *)[self.photoCommentsNavigationController topViewController];
}

- (UIView *)hostingViewForCommentView {
    if (!_hostingViewForCommentView) {
        _hostingViewForCommentView = [[UIView alloc] init];
    }
    return _hostingViewForCommentView;
}

- (FTFImage *)photo {
    return self.albumPhotos[self.currentIndex];
}

- (id)initWithDelegate:(id<MWPhotoBrowserDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        self.displayActionButton = NO;
        self.zoomPhotosToFill = NO;
        self.displayNavArrows = YES;
        self.hideControlsWhenDragging = NO;

        UIBarButtonItem *fbCommentsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Comment"] style:UIBarButtonItemStylePlain target:self action:@selector(fbCommentsButtonTapped)];
        
        self.imageViewForButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ThumbUp"]];
        self.imageViewForButton.autoresizingMask = UIViewAutoresizingNone;
        self.imageViewForButton.contentMode = UIViewContentModeCenter;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.adjustsImageWhenHighlighted = YES;
        button.frame = CGRectMake(0, 0, 40, 40);
        
        [button addSubview:self.imageViewForButton];
        [button addTarget:self action:@selector(fbLikeButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
        self.imageViewForButton.center = button.center;
        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.rightToolbarButtons = @[barItem];
        self.leftToolbarButtons = @[fbCommentsButton];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self photoCommentsVC].delegate = self;
    
    self.navigationBarLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.navigationBarLabel.font = [UIFont boldSystemFontOfSize:15];
    self.navigationBarLabel.shadowColor = [UIColor clearColor];
    self.navigationBarLabel.textColor = [UIColor orangeColor];
    self.navigationItem.titleView = self.navigationBarLabel;
    
    [self updateNavTitleAndLikeButton];
}

- (void)showNextPhotoAnimated:(BOOL)animated {  // When user taps the next arrow
    [super showNextPhotoAnimated:animated];
    [self updateNavTitleAndLikeButton];
}

- (void)showPreviousPhotoAnimated:(BOOL)animated {  // When user taps the previous arrow
    [super showPreviousPhotoAnimated:animated];
    [self updateNavTitleAndLikeButton];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // Need this dispatch_after because this method gets called before setCurrentPhotoIndex
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateNavTitleAndLikeButton];
    });
}

- (void)setCurrentPhotoIndex:(NSUInteger)index {   // This method only called once when photoBrowser is initialized
    [super setCurrentPhotoIndex:index];
    self.imageViewForButton.image = [UIImage imageNamed:self.photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"];
}

#pragma mark - Action Methods

- (void)fbLikeButtonTapped {
    FTFImage *photo = self.albumPhotos[self.currentIndex];
    BOOL hasTappedLikeButtonOnce = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasTappedLikeButtonOnce"];
    BOOL hasTappedUnlikeButtonOnce = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasTappedUnlikeButtonOnce"];
    
    NSString *messageString;
    BOOL shouldShowAlert = NO;
    
    if (!photo.isLiked && !hasTappedLikeButtonOnce) {  // if the user taps to like a photo and they haven't liked a photo before
        shouldShowAlert = YES;
        messageString = @"This will publish a like to Facebook.  Do you wish to continue?";
    } else if (photo.isLiked && !hasTappedUnlikeButtonOnce) {
        shouldShowAlert = YES;
        messageString = @"This will delete a like from Facebook.  Do you wish to continue?";
    }
    
    if (shouldShowAlert) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:messageString preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (photo.isLiked) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTappedUnlikeButtonOnce"];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTappedLikeButtonOnce"];
            }
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self postLikeButtonTappedNotificationWithCurrentPhotoIndex];
            
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            anim.duration = 0.2;
            anim.repeatCount = 1;
            anim.autoreverses = YES;
            anim.removedOnCompletion = YES;
            anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)];
            [self.imageViewForButton.layer addAnimation:anim forKey:nil];
            UIImage *thumbUnfilled = [UIImage imageNamed:@"ThumbUp"];
            UIImage *thumbFilled = [UIImage imageNamed:@"ThumbUpFilled"];
            [UIView transitionWithView:self.imageViewForButton
                              duration:0.2f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imageViewForButton.image = !self.photo.isLiked ? thumbFilled : thumbUnfilled;
                            } completion:NULL];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
        
    } else {

        [self postLikeButtonTappedNotificationWithCurrentPhotoIndex];
        
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.duration = 0.2;
        anim.repeatCount = 1;
        anim.autoreverses = YES;
        anim.removedOnCompletion = YES;
        anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)];
        [self.imageViewForButton.layer addAnimation:anim forKey:nil];
        UIImage *thumbUnfilled = [UIImage imageNamed:@"ThumbUp"];
        UIImage *thumbFilled = [UIImage imageNamed:@"ThumbUpFilled"];
        [UIView transitionWithView:self.imageViewForButton
                          duration:0.2f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.imageViewForButton.image = !self.photo.isLiked ? thumbFilled : thumbUnfilled;
                        } completion:NULL];
    }
}

- (void)postLikeButtonTappedNotificationWithCurrentPhotoIndex {
    NSNotification *didPressLike = [NSNotification notificationWithName:didPressLikeNotification object:@(self.currentIndex)];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotification:didPressLike];
}

- (void)fbCommentsButtonTapped {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *photoCommentsNavController = [storyboard instantiateViewControllerWithIdentifier:@"photoCommentsNavigationController"];
    FTFPhotoCommentsViewController *photoCommentsVC = (FTFPhotoCommentsViewController *)[photoCommentsNavController topViewController];
    
    photoCommentsVC.photo = self.albumPhotos[self.currentIndex];

    [self presentViewController:photoCommentsNavController animated:true completion:nil];
}

#pragma mark - Photo Comments VC Delegate

- (void)photoCommentsViewControllerDidTapDoneButton {
    [UIView animateWithDuration:0.7
                          delay:0.1
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.1
                        options:0
                     animations:^{
                         CGRect newRectLocation = CGRectMake(self.hostingViewForCommentView.frame.origin.x, 1000, self.hostingViewForCommentView.frame.size.width, self.hostingViewForCommentView.frame.size.height);
                         self.hostingViewForCommentView.frame = newRectLocation;
                   } completion:nil];
}

- (void)updateNavTitleAndLikeButton {
    FTFImage *photo = self.albumPhotos[self.currentIndex];
    self.navigationBarLabel.text = (photo.title != nil) ? [@" " stringByAppendingString:photo.title] : @"";
    self.imageViewForButton.image = [UIImage imageNamed:self.photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

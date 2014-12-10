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

@interface FTFPhotoBrowserViewController () <FTFPhotoCommentsViewControllerDelegate>

@property (nonatomic, strong) WYPopoverController *photoCommentsPopoverController;
@property (nonatomic, strong) UINavigationController *photoCommentsNavigationController;
@property (nonatomic, strong) UIView *hostingViewForCommentView;
@property (nonatomic, strong) UIImageView *imageViewForButton;

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

- (id)initWithDelegate:(id<MWPhotoBrowserDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        self.displayActionButton = NO;
        self.zoomPhotosToFill = NO;
        self.displayNavArrows = YES;
        self.hideControlsWhenDragging = NO;

        UIBarButtonItem *fbCommentsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"messageIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(fbCommentsButtonTapped)];
        
        self.imageViewForButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Facebook_like_button_thumb.png"]];
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
}

#pragma mark - Action Methods

- (void)fbLikeButtonTapped {

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.2;
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    anim.removedOnCompletion = YES;
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
    [self.imageViewForButton.layer addAnimation:anim forKey:nil];
    
    NSInteger indexOfPhoto = self.currentIndex;
    FTFImage *photoAtIndex = self.albumPhotos[indexOfPhoto];
    
//    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoAtIndex.photoID]
//                                 parameters:nil
//                                 HTTPMethod:@"POST"
//                          completionHandler:^(
//                                              FBRequestConnection *connection,
//                                              id result,
//                                              NSError *error
//                                              ) {
//                              
//                          }];
    
    [[FiftyTwoFrames sharedInstance] publishPhotoLikeWithPhotoID:photoAtIndex.photoID completionBlock:^(NSError *error) {
        NSLog(@"Error: %@", error);
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Couldn't like this photo, sorry!"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)fbCommentsButtonTapped {
    [self photoCommentsVC].photo = self.albumPhotos[self.currentIndex];

    UIView *navigationView = self.navigationController.view;
    self.hostingViewForCommentView.frame = navigationView.bounds;
    self.hostingViewForCommentView.bounds = self.view.bounds;
    
    [self.hostingViewForCommentView addSubview:self.photoCommentsNavigationController.view];
    [navigationView addSubview:self.hostingViewForCommentView];
    self.hostingViewForCommentView.frame = (CGRect) {
        CGPointMake(0, navigationView.frame.size.height),
        self.hostingViewForCommentView.frame.size
    };
    self.hostingViewForCommentView.center = CGPointMake(navigationView.center.x, self.hostingViewForCommentView.center.y);
    [UIView animateWithDuration:0.5
                           delay:0.1
          usingSpringWithDamping:0.8
           initialSpringVelocity:0.1
                         options:0
                      animations:^{
                          self.hostingViewForCommentView.center = self.view.center;
                    } completion:nil];
    [[self photoCommentsVC].tableView reloadData];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

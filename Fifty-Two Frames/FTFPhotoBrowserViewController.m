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
#import <FacebookSDK/FacebookSDK.h>

@interface FTFPhotoBrowserViewController () <FTFPhotoCommentsViewControllerDelegate>

@property (nonatomic, strong) WYPopoverController *photoCommentsPopoverController;
@property (nonatomic, strong) UINavigationController *photoCommentsNavigationController;
@property (nonatomic, strong) UIView *hostingView;

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

- (UIView *)hostingView {
    if (!_hostingView) {
        _hostingView = [[UIView alloc] init];
    }
    return _hostingView;
}

- (id)initWithDelegate:(id<MWPhotoBrowserDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        self.displayActionButton = NO;
        self.zoomPhotosToFill = NO;
        self.displayNavArrows = YES;
        self.hideControlsWhenDragging = NO;
        self.enableGrid = YES;
        
        //    UIBarButtonItem *fbLikeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Facebook_like_button_thumb.png"] style:UIBarButtonItemStylePlain target:self action:@selector(fbLikeButtonTapped)];
        UIBarButtonItem *fbCommentsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"messageIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(fbCommentsButtonTapped)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Facebook_like_button_thumb.png"]];
        imageView.autoresizingMask = UIViewAutoresizingNone;
        imageView.contentMode = UIViewContentModeCenter;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.adjustsImageWhenHighlighted = YES;
        button.frame = CGRectMake(0, 0, 40, 40);
        [button addSubview:imageView];
        [button addTarget:self action:@selector(fbLikeButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
        imageView.center = button.center;
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
        // Do any additional setup after loading the view.
}

- (void)fbLikeButtonTapped {
    //    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
    //    anim.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 400, 400)];
    //    [self.imageView.layer pop_addAnimation:anim forKey:@"myKey"];
    
    NSInteger indexOfPhoto = self.currentIndex;
    FTFImage *photoAtIndex = self.albumPhotos[indexOfPhoto];
    
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoAtIndex.photoID]
                                 parameters:nil
                                 HTTPMethod:@"POST"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              NSLog(@"Result: %@, Error: %@", result, error);
                          }];
    
    
}

- (void)fbCommentsButtonTapped {
    NSInteger indexOfPhoto = self.currentIndex;
    FTFImage *photoAtIndex = self.albumPhotos[indexOfPhoto];
    
    if (photoAtIndex.photoComments != nil) {
        self.photoCommentsVC.photoComments = photoAtIndex.photoComments;
    }
    
    UIView *navigationView = self.navigationController.view;
    self.hostingView.frame = navigationView.bounds;
    self.hostingView.bounds = self.view.bounds;
    
    self.photoCommentsNavigationController.view.frame = CGRectInset(self.hostingView.bounds, 15, 15);
    [self.hostingView addSubview:self.photoCommentsNavigationController.view];
    [navigationView addSubview:self.hostingView];
    self.hostingView.frame = (CGRect) {
        CGPointMake(0, navigationView.frame.size.height),
        self.hostingView.frame.size
    };
    self.hostingView.center = CGPointMake(navigationView.center.x, self.hostingView.center.y);
    [UIView animateWithDuration:0.5
                           delay:0.1
          usingSpringWithDamping:0.8
           initialSpringVelocity:0.1
                         options:0
                      animations:^{
                          self.hostingView.center = self.view.center;
                    } completion:nil];
    
}

- (void)dismissPhotoCommentsViewController {
    [UIView animateWithDuration:0.7
                          delay:0.1
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.1
                        options:0
                     animations:^{
                         CGPoint newCenter = CGPointMake(0, 1000);
                         self.hostingView.center = newCenter;
                   } completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

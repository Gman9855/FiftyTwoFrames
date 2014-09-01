//
//  FTFPhotoContainerViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/30/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoContainerViewController.h"
#import "FTFPhotoBrowserViewController.h"
#import "FTFPhotoCommentsViewController.h"
#import "FTFContentTableViewController.h"
#import "FTFImage+MWPhotoAdditions.h"

@interface FTFPhotoContainerViewController ()

@property (nonatomic, strong) FTFPhotoBrowserViewController *photoBrowserViewController;
@property (nonatomic, strong) UINavigationController *photoCommentsNavigationController;
@property (nonatomic, strong) NSArray *albumPhotos; // of FTFImage
@property (nonatomic, strong) NSMutableArray *photosForUseInBrowser; // of MWPhoto

@end

@implementation FTFPhotoContainerViewController

- (id)initWithAlbumPhotos:(NSArray *)albumPhotos andIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _photoCommentsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"photoCommentsNavigationController"];
        _photoBrowserViewController = [[FTFPhotoBrowserViewController alloc] initWithDelegate:self];
        _photosForUseInBrowser = [NSMutableArray new];
        for (FTFImage *image in albumPhotos) {
            [_photosForUseInBrowser addObject:image.browserPhoto];
        }
        [_photoBrowserViewController setCurrentPhotoIndex:index];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.photoBrowserViewController willMoveToParentViewController:self];
    [self addChildViewController:self.photoBrowserViewController];
    [self.view addSubview:self.photoBrowserViewController.view];
    [self.photoBrowserViewController didMoveToParentViewController:self];
    
    [self.photoCommentsNavigationController willMoveToParentViewController:self];
    [self addChildViewController:self.photoCommentsNavigationController];
    [self.photoCommentsNavigationController didMoveToParentViewController:self];
    
//    [self.view addSubview:self.photoCommentsNavigationController.view];
//    self.photoBrowserViewController.view.frame = self.view.bounds;
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSArray *viewControllers = self.navigationController.viewControllers;
    for (UIViewController *vc in viewControllers) {
        if ([viewControllers isKindOfClass:[FTFContentTableViewController class]]) {
            NSInteger indexOfPhoto = self.photoBrowserViewController.currentIndex;
            FTFImage *photo = self.albumPhotos[indexOfPhoto];
            [(FTFContentTableViewController *)vc scrollToPhoto:photo];
            break;
        }
    }
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

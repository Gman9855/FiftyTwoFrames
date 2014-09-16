//
//  FTFContentTableViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/2/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFContentTableViewController.h"
#import "FTFTableViewCell.h"
#import "UIImageView+WebCache.h"
#import "FTFImage.h"
#import "FTFAlbumSelectionMenuViewController.h"
#import "MBProgressHUD.h"
#import "MWPhotoBrowser.h"
#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import <POP/POP.h>
#import "FTFPhotoBrowserViewController.h"
#import "FTFPhotoContainerViewController.h"
#import "FTFImage+MWPhotoAdditions.h"
#import "FTFPhotoCollectionGridViewController.h"
#import "FiftyTwoFrames.h"
#import "FTFAlbumCategoryCollection.h"

@interface FTFContentTableViewController () <UINavigationControllerDelegate, MWPhotoBrowserDelegate, FTFAlbumSelectionMenuViewControllerDelegate, FTFPhotoCollectionGridViewControllerDelegate>

@property (nonatomic, strong) FTFAlbumSelectionMenuViewController *albumSelectionMenuViewController;
@property (nonatomic, strong) UINavigationController *albumSelectionMenuNavigationController;
@property (nonatomic, strong) FTFPhotoBrowserViewController *photoBrowser;
@property (nonatomic, strong) FTFPhotoCollectionGridViewController *photoGrid;
@property (nonatomic, strong) FTFAlbumCategoryCollection *photoAlbumCollection;
@property (nonatomic, strong) FTFAlbum *albumToDisplay;
@property (nonatomic, strong) FTFAlbumCollection *weeklyThemeAlbums;
@property (nonatomic, strong) FTFAlbumCollection *photoWalksAlbums;
@property (nonatomic, strong) FTFAlbumCollection *miscellaneousSubmissionsAlbums;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, strong) NSArray *browserPhotos;
@property (nonatomic, strong) UILabel *navBarTitle;
@property (nonatomic, strong) NSArray *albumPhotos;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *hostingView;
@property (nonatomic, strong) NSArray *thumbnailPhotosForGrid;

@end

static NSString * const reuseIdentifier = @"photo";
BOOL albumSelectionChanged = NO;

@implementation FTFContentTableViewController

#pragma mark - Lazy Load

- (UIView *)hostingView {
    if (!_hostingView) {
        _hostingView = [UIView new];
    }
    return _hostingView;
}

- (UINavigationController *)albumSelectionMenuNavigationController {
    if (!_albumSelectionMenuNavigationController) {
        _albumSelectionMenuNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"albumListNavController"];
    }
    return _albumSelectionMenuNavigationController;
}

- (FTFAlbumSelectionMenuViewController *)albumSelectionMenuViewController {
    return (FTFAlbumSelectionMenuViewController *)[self.albumSelectionMenuNavigationController topViewController];
}

- (FTFPhotoCollectionGridViewController *)photoGrid {
    if (!_photoGrid) {
        _photoGrid = [self.storyboard instantiateViewControllerWithIdentifier:@"grid"];
        _photoGrid.delegate = self;
    }
    return _photoGrid;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.albumSelectionMenuViewController.delegate = self;
    
    self.navigationController.toolbarHidden = YES;
    
    [self setUpNavigationBarTitle];

    self.navigationController.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setUpActivityIndicator];

    [[FiftyTwoFrames sharedInstance] requestAlbumCollectionWithCompletionBlock:^(FTFAlbumCategoryCollection *albumCollection,
                                                                                 NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There was an error loading this week's photos" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
            NSLog(@"%@", error);
        } else {
            self.photoAlbumCollection = albumCollection;
            [self retrievedAlbumCollection];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumSelectionChanged:)
                                                 name:@"albumSelectedNotification"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
}

- (void)setUpNavigationBarTitle {
    self.navBarTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 85)];
    self.navBarTitle.textAlignment = NSTextAlignmentCenter;
    self.navBarTitle.text = @"Fifty-Two Frames";
    self.navBarTitle.textColor = [UIColor whiteColor];
    self.navBarTitle.font = [UIFont boldSystemFontOfSize:14];
    self.navBarTitle.numberOfLines = 2;
    self.navigationItem.titleView = self.navBarTitle;
}

- (void)setUpActivityIndicator {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading photos";
    hud.yOffset = -60;
}

- (void)retrievedAlbumCollection {
    self.weeklyThemeAlbums = [self.photoAlbumCollection albumCollectionForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    
    FTFAlbumSelectionMenuViewController *albumSelectionMenuVC = (FTFAlbumSelectionMenuViewController *)[self.albumSelectionMenuNavigationController topViewController];
    albumSelectionMenuVC.weeklySubmissions = [self.photoAlbumCollection albumCollectionForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    albumSelectionMenuVC.photoWalks = [self.photoAlbumCollection albumCollectionForCategory:FTFAlbumCollectionCategoryPhotoWalks];
    albumSelectionMenuVC.miscellaneousAlbums = [self.photoAlbumCollection albumCollectionForCategory:FTFAlbumCollectionCategoryMiscellaneous];
    
    FTFAlbum *album = self.weeklyThemeAlbums.albums.firstObject;
    albumSelectionMenuVC.selectedAlbumCollection = [albumSelectionMenuVC albumsForGivenYear:album.yearCreated
                                          fromAlbumCollection:self.weeklyThemeAlbums];
    albumSelectionMenuVC.selectedAlbumYear = album.yearCreated;
    albumSelectionMenuVC.yearButton.title = album.yearCreated;
    self.albumToDisplay = self.weeklyThemeAlbums.albums.firstObject;
    [[FiftyTwoFrames sharedInstance] requestUserWithCompletionBlock:^(FTFUser *user) {
        [[FiftyTwoFrames sharedInstance] requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                                         limit:200
                                                               completionBlock:^(NSArray *photos, NSError *error) {
                                                                   
                                                                   [self populateAlbumPhotosResultsWithPhotos:photos error:error];
                                                               }];
    }];
    
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    albumSelectionChanged = YES;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.photoBrowser setCurrentPhotoIndex:0];
    self.photoGrid.gridPhotos = nil;
    
    self.albumToDisplay = [notification.userInfo objectForKey:@"selectedAlbum"];
    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                                    limit:200
                                                          completionBlock:^(NSArray *photos, NSError *error) {
                                                              
            [self populateAlbumPhotosResultsWithPhotos:photos error:error];
    }];
}

- (void)populateAlbumPhotosResultsWithPhotos:(NSArray *)photos error:(NSError *)error {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    if (error) {
        if (error.code != 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"An error occured trying to grab this album's photos"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    if ([photos count]) {
        self.albumPhotos = photos;
        self.photoGrid.gridPhotos = photos;
        [self.tableView reloadData];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
        [UIView animateWithDuration:1.5 animations:^{
            self.navigationItem.titleView.alpha = 0.0;
            self.navBarTitle.text = self.albumToDisplay.name;
            self.navigationItem.titleView.alpha = 1.0;
        }];
        

//    } else {
//        [MBProgressHUD hideHUDForView:self.view animated:NO];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                            message:@"Sorry, no photos found for this album"
//                                                           delegate:self
//                                                  cancelButtonTitle:@"Okay"
//                                                  otherButtonTitles:nil];
//            [alert show];
//        });
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    FTFImage *photo = self.albumPhotos[indexPath.row];
    FTFTableViewCell *ftfCell = (FTFTableViewCell *)cell;

    if (![photo.photoComments isEqual:[NSNull null]]) {
        ftfCell.commentsCountLabel.text = [NSString stringWithFormat:@"%d", [photo.photoComments count]];
    }
    
    ftfCell.likesCountLabel.text = [NSString stringWithFormat:@"%ld", (long)photo.photoLikesCount];
    
    if (![photo.photoDescription isEqual:[NSNull null]]) {
        ftfCell.descriptionLabel.text = photo.photoDescription;
    } else {
        ftfCell.descriptionLabel.text = @"";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [photo requestImageWithSize:FTFImageSizeLarge
                    completionBlock:^(UIImage *image, NSError *error, BOOL isCached) {
            if (error) return;
            
            FTFTableViewCell *cell = (FTFTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            
            if (!isCached) {
                CATransition *t = [CATransition animation];
                t.duration = 0.30;
                t.type = kCATransitionFade;
                [cell.photo.layer addAnimation:t forKey:nil];
            }
            cell.photo.image = image;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }];
    });
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([self.albumPhotos count]) {
        FTFImage *image = self.albumPhotos[indexPath.row];
        [image cancel];
    } else {
        return;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.albumPhotos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FTFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    
    [self setUpPhotoBrowserForTappedPhotoAtRow];
    [self.photoBrowser setCurrentPhotoIndex:indexPath.row];
    [self.navigationController pushViewController:self.photoBrowser animated:YES];
}

- (void)setUpPhotoBrowserForTappedPhotoAtRow {
    self.photoBrowser = [[FTFPhotoBrowserViewController alloc]
                                       initWithDelegate:self];
    if (albumSelectionChanged || ![self.browserPhotos count]) {
        self.browserPhotos = [self photosCompatibleForUseInPhotoBrowserWithSize:FTFImageSizeLarge];
        //repopulate browserPhotos with newly selected album
        albumSelectionChanged = NO;
    }
    self.photoBrowser.albumPhotos = self.albumPhotos;
}

#pragma mark - MWPhotoBrowser

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.browserPhotos.count) {
        return [self.browserPhotos objectAtIndex:index];
    }
    return nil;
}

- (NSArray *)photosCompatibleForUseInPhotoBrowserWithSize:(FTFImageSize)size {
    NSMutableArray *photos = [NSMutableArray new];
    for (FTFImage *image in self.albumPhotos) {
        [photos addObject:[image browserPhotoWithSize:size]];
    }
    return [photos copy];
}

- (void)pushPhotoBrowserAtPhotoIndex:(NSInteger)index {
    [self setUpPhotoBrowserForTappedPhotoAtRow];
    [self.photoBrowser setCurrentPhotoIndex:index];
    [self.navigationController pushViewController:self.photoBrowser animated:YES];
}

#pragma mark - FTFAlbumSelectionMenuViewController Delegate

- (void)albumSelectionMenuViewControllerdidTapDismissButton {
    [UIView animateWithDuration:0.7
                          delay:0.1
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.1
                        options:0
                     animations:^{
                         CGRect newRectLocation = CGRectMake(self.hostingView.frame.origin.x, 1000, self.hostingView.frame.size.width, self.hostingView.frame.size.height);
                         self.hostingView.frame = newRectLocation;
                     } completion:nil];
}

#pragma mark - FTFPhotoCollectionGridViewController Delegate

- (void)photoCollectionGridDidSelectPhotoAtIndex:(NSInteger)index {
    [self pushPhotoBrowserAtPhotoIndex:index];
}

#pragma mark - Actions

- (IBAction)settingsButtonTapped:(UIBarButtonItem *)sender;
{
    UIView *navigationView = self.navigationController.view;
    self.hostingView.frame = navigationView.bounds;
    self.hostingView.bounds = self.view.bounds;
    
//    self.albumSelectionMenuNavigationController.view.frame = CGRectInset(self.hostingView.bounds, 15, 15);
    self.albumSelectionMenuNavigationController.view.frame = self.hostingView.bounds;
    [self.hostingView addSubview:self.albumSelectionMenuNavigationController.view];
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

- (IBAction)menuButtonTapped:(UIBarButtonItem *)sender;
{
    
}

- (IBAction)likeIconTapped:(UIButton *)sender {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.2;
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    anim.removedOnCompletion = YES;
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
    [sender.layer addAnimation:anim forKey:nil];
    
    
}

- (IBAction)infoButtonTapped:(UIBarButtonItem *)sender {
    
}

- (IBAction)gridButtonTapped:(UIBarButtonItem *)sender {
    [self.navigationController pushViewController:self.photoGrid animated:YES];
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if (self.photoBrowser != nil && viewController == self) {
        NSInteger currentIndex = self.photoBrowser.currentIndex;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:currentIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
}

@end

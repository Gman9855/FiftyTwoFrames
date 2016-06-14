//
//  FTFPhotoCollectionViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoCollectionGridViewController.h"
#import "FTFImage.h"
#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"
#import "FTFCollectionViewCell.h"
#import "FTFCollectionViewListCell.h"
#import "FTFCollectionViewGridCell.h"
#import "MWPhotoBrowser.h"
#import "FiftyTwoFrames.h"
#import "FTFCollectionReusableView.h"
#import "FiftyTwoFrames-Swift.h"
#import "FTFGridLayout.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "FTFNavigationBarAlbumTitle.h"
#import "FTFLikeButton.h"
#import "FTFPhotoBrowserViewController.h"
#import "FTFAlbumSelectionMenuViewController.h"
#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import "FTFImage.h"
#import "FTFImage+MWPhotoAdditions.h"
#import "FTFCustomCaptionView.h"
#import "FTFAlbumDescriptionViewController.h"
#import "FTFFiltersViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#include "REFrostedViewController.h"
#import "FTFSideMenuViewController.h"

@interface FTFPhotoCollectionGridViewController () <CHTCollectionViewDelegateWaterfallLayout, UINavigationControllerDelegate, MWPhotoBrowserDelegate, FTFFiltersViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) FTFCollectionReusableView *collectionReusableView;
@property (nonatomic, strong) UILabel *navBarTitle;
@property (nonatomic, strong) FTFNavigationBarAlbumTitle *navBarAlbumTitle;
@property (nonatomic, strong) FTFListLayout *listLayout;
@property (nonatomic, strong) CHTCollectionViewWaterfallLayout *gridLayout;
@property (nonatomic, strong) UICollectionViewLayout *currentLayout;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *layoutToggleButton;
@property (nonatomic, strong) FTFAlbumSelectionMenuViewController *albumSelectionMenuViewController;
@property (nonatomic, strong) UINavigationController *albumSelectionMenuNavigationController;
@property (nonatomic, strong) FTFPhotoBrowserViewController *photoBrowser;
@property (nonatomic, strong) FTFAlbum *albumToDisplay;
@property (nonatomic, strong) FTFAlbumCollection *photoWalksAlbums;
@property (nonatomic, strong) FTFAlbumCollection *miscellaneousSubmissionsAlbums;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIButton *refreshAlbumPhotosButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *gridButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *albumInfoButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButton;
@property (strong, nonnull) NSArray *cachedAlbumPhotos;
@property (nonatomic, strong) UINavigationController *filtersNavController;
@property (nonatomic, strong) FTFFiltersViewController *filtersViewController;
@property (nonatomic, strong) NSString *searchTerm;

@end

static NSString * const reuseIdentifier = @"photo";
BOOL albumSelectionChanged = NO;
BOOL _morePhotosToLoad = NO;
BOOL didLikePhotoFromBrowser = NO;

@implementation FTFPhotoCollectionGridViewController {
    BOOL _albumSelectionChanged;
    BOOL _morePhotosToLoad;
    BOOL _finishedPaging;
    BOOL _unfilteredPhotosFinishedPaging;
    BOOL _didUpdateCells;
    BOOL _layoutDidChange;
    BOOL _didPageNextBatchOfPhotos;
    BOOL _isCurrentlyLoadingMorePhotos;
    BOOL _showingFilteredResults;
}

- (UINavigationController *)albumSelectionMenuNavigationController {
    if (!_albumSelectionMenuNavigationController) {
        _albumSelectionMenuNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"albumListNavController"];
        UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *beView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        beView.frame = self.view.bounds;
        
        _albumSelectionMenuNavigationController.view.frame = self.view.bounds;
        _albumSelectionMenuNavigationController.view.backgroundColor = [UIColor clearColor];
        [_albumSelectionMenuNavigationController.view insertSubview:beView atIndex:0];
        _albumSelectionMenuNavigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    return _albumSelectionMenuNavigationController;
}

- (FTFAlbumSelectionMenuViewController *)albumSelectionMenuViewController {
    return (FTFAlbumSelectionMenuViewController *)[self.albumSelectionMenuNavigationController topViewController];
}

- (FTFNavigationBarAlbumTitle *)navBarAlbumTitle {
    if (!_navBarAlbumTitle) {
        _navBarAlbumTitle = [[FTFNavigationBarAlbumTitle alloc] initWithTitle:@"52Frames"];
    }
    
    return _navBarAlbumTitle;
}

- (UINavigationController *)filtersNavController {
    if (!_filtersNavController) {
        _filtersNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"filtersNavigationController"];
    }
    
    return _filtersNavController;
}

- (FTFFiltersViewController *)filtersViewController {
    if (!_filtersViewController) {
        _filtersViewController = (FTFFiltersViewController *)self.filtersNavController.topViewController;
    }
    return _filtersViewController;
}

- (void)setGridPhotos:(NSArray *)gridPhotos {
    _gridPhotos = gridPhotos;
}

#pragma mark - View controller

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
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panReceivedInView:)];
    panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:panGestureRecognizer];
    self.listLayout = [[FTFListLayout alloc] init];
    self.gridLayout = [[CHTCollectionViewWaterfallLayout alloc] init];
    self.gridLayout.columnCount = 2;
    self.gridLayout.minimumColumnSpacing = 5;
    self.gridLayout.minimumInteritemSpacing = 5;
    self.collectionView.collectionViewLayout = self.listLayout;
    self.currentLayout = self.listLayout;
    
    self.gridButton.enabled = NO;
    self.albumInfoButton.enabled = NO;
    self.collectionView.userInteractionEnabled = NO;
    self.navigationController.toolbarHidden = YES;
    self.navigationController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumSelectionChanged:)
                                                 name:@"albumSelectedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(updateLikeCountLabel:)
                                                name:didPressLikeNotification
                                              object:nil];
    
    [self showProgressHudWithText:@"Loading this week's photos"];
    [self.albumSelectionMenuViewController fetchAlbumCategoryCollection];
    [[FiftyTwoFrames sharedInstance] requestLatestWeeklyThemeAlbumWithCompletionBlock:^(FTFAlbum *album, NSError *error, BOOL finishedPaging) {
        self.albumToDisplay = album;
        [self populateAlbumPhotosResultsWithPhotos:album.photos error:error finishedPaging:finishedPaging];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.titleView = self.navBarAlbumTitle;
    self.navigationController.toolbarHidden = NO;
}

- (void)updateLikeCountLabel:(NSNotification *)notification {
    didLikePhotoFromBrowser = YES;
    int indexOfPhoto = [notification.object intValue];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:indexOfPhoto inSection:0];
    FTFImage *photoAtIndex = self.gridPhotos[indexOfPhoto];
    FTFCollectionViewCell *cell = (FTFCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:ip];
    [self handlePhotoLikeWithCell:cell andPhoto:photoAtIndex];
}

- (void)showProgressHudWithText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    if (![text isEqualToString:@""]) {
        hud.labelText = text;
        hud.labelFont = [UIFont fontWithName:@"Lato-Regular" size:16];
    }
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    self.refreshAlbumPhotosButton.hidden = YES;
    self.collectionView.userInteractionEnabled = NO;
    self.gridButton.enabled = NO;
    self.albumInfoButton.enabled = NO;
    albumSelectionChanged = YES;
    _morePhotosToLoad = NO;
    _showingFilteredResults = NO;
    [self.photoBrowser setCurrentPhotoIndex:0];
    
    self.albumToDisplay = [notification.userInfo objectForKey:@"selectedAlbum"];
    [self showProgressHudWithText:[NSString stringWithFormat:@"Loading %@", self.albumToDisplay.name]];

    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                          completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                                                              [self setFilterIconEnabled:NO];
                                                              [self populateAlbumPhotosResultsWithPhotos:photos error:error finishedPaging:finishedPaging];
                                                          }];
}

- (void)populateAlbumPhotosResultsWithPhotos:(NSArray *)photos
                                       error:(NSError *)error
                              finishedPaging: (BOOL)finishedPaging {
    _finishedPaging = finishedPaging;
    _unfilteredPhotosFinishedPaging = finishedPaging;

    [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
    self.collectionView.userInteractionEnabled = YES;
    if (self.gridPhotos) {
//        self.settingsButton.enabled = YES;
        self.gridButton.enabled = YES;
        self.albumInfoButton.enabled = YES;
    }
    if (error) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"There was an error loading this album's photos."
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        
        if (!self.gridPhotos.count) {     // Check whether we're loading the initial latest album.  We don't want to
            // display the refresh button if we already have an album showing
            self.collectionView.scrollEnabled = NO;
            if (!self.refreshAlbumPhotosButton) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.refreshAlbumPhotosButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    [self.refreshAlbumPhotosButton addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [self.refreshAlbumPhotosButton setImage:[UIImage imageNamed:@"Refresh"] forState:UIControlStateNormal];
                    [self.refreshAlbumPhotosButton sizeToFit];
                    self.refreshAlbumPhotosButton.center = [self.view convertPoint:self.view.center fromView:self.view.superview];
                    
                    [self.view addSubview:self.refreshAlbumPhotosButton];
                });
            } else {
                self.refreshAlbumPhotosButton.hidden = NO;
            }
        }
        return;
    }
    
    if ([photos count]) {
        self.collectionView.scrollEnabled = YES;
        self.gridPhotos = photos;
        self.cachedAlbumPhotos = photos;
        _finishedPaging = finishedPaging;
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
            [self.collectionView scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        });
        
//        self.settingsButton.enabled = YES;
        self.gridButton.enabled = YES;
        self.albumInfoButton.enabled = YES;
        
        [UIView animateWithDuration:1.5 animations:^{
            self.navigationItem.titleView.alpha = 0.0;
            [self.navBarAlbumTitle setAttributedTitleWithText:self.albumToDisplay.name];
            self.navigationItem.titleView.alpha = 1.0;
        }];
        
        _morePhotosToLoad = YES;
    }
}

#pragma mark - Action Methods

- (IBAction)albumMenuButtonTapped:(UIBarButtonItem *)sender {
    [self presentViewController:self.albumSelectionMenuNavigationController animated:true completion:nil];
}
- (IBAction)searchButtonTapped:(UIBarButtonItem *)sender {
    self.filtersViewController.delegate = self;
    [self presentViewController:self.filtersNavController animated:YES completion:nil];
}

- (IBAction)sideMenuButtonTapped:(UIBarButtonItem *)sender {
    [self.frostedViewController presentMenuViewController];
}

- (IBAction)toggleLayout:(UIBarButtonItem *)sender {
    _layoutDidChange = YES;
    BOOL isListLayout = self.collectionView.collectionViewLayout == self.listLayout;
    UICollectionViewLayout *layout = isListLayout ? self.gridLayout : self.listLayout;
    NSString *layoutType = isListLayout ? @"grid" : @"list";
    
    self.currentLayout = layout;
    self.layoutToggleButton.tintColor = isListLayout ? [UIColor orangeColor] : [UIColor whiteColor];
    
    
    NSDictionary *userInfo = @{@"layout": layout, @"layoutType": layoutType};
    
    NSArray *visibleCells = [self.collectionView visibleCells];
    FTFCollectionViewCell *firstPhoto = (FTFCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    BOOL containsFirstPhoto = [visibleCells containsObject:firstPhoto];
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.865 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        [self.collectionView setCollectionViewLayout:layout animated:NO];
        if (containsFirstPhoto) {
            [self.collectionView setContentOffset:CGPointZero];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        
        [self postLayoutNotification:userInfo];
        
    } completion:nil];
}

- (IBAction)albumInfoButtonTapped:(UIBarButtonItem *)sender {
    FTFAlbumDescriptionViewController *albumDescriptionVC = (FTFAlbumDescriptionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"albumDescriptionVC"];
    albumDescriptionVC.album = self.albumToDisplay;
    UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *beView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    beView.frame = self.view.bounds;
    
    albumDescriptionVC.view.frame = self.view.bounds;
    albumDescriptionVC.view.backgroundColor = [UIColor clearColor];
    [albumDescriptionVC.view insertSubview:beView atIndex:0];
    albumDescriptionVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    albumDescriptionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:albumDescriptionVC animated:YES completion:nil];
}

- (IBAction)likeButtonTapped:(FTFLikeButton *)sender {
    // Find which cell the like came from
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:rootViewPoint];
    
    FTFImage *photo = self.gridPhotos[indexPath.row];
    FTFCollectionViewCell *cell = (FTFCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
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
            [sender animateTap];
            if (photo.isLiked) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTappedUnlikeButtonOnce"];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTappedLikeButtonOnce"];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self handlePhotoLikeWithCell:cell andPhoto:photo];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
        
    } else {
        
        [sender animateTap];
        [self handlePhotoLikeWithCell:cell andPhoto:photo];
    }
}

- (void)handlePhotoLikeWithCell:(FTFCollectionViewCell *)cell andPhoto:(FTFImage *)photo {
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        [cell.likeButton setImage:[UIImage imageNamed:!photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"] forState:UIControlStateNormal];
        if (!photo.isLiked) {
            [[FiftyTwoFrames sharedInstance] publishPhotoLikeWithPhotoID:photo.photoID completionBlock:^(NSError *error) {
                if (!error) {
                    photo.likesCount++;
                    photo.isLiked = YES;
                    cell.photoLikeCount.text = [NSString stringWithFormat:@"%d", (int)photo.likesCount];
                }
            }];
        } else {
            [[FiftyTwoFrames sharedInstance] deletePhotoLikeWithPhotoID:photo.photoID completionBlock:^(NSError *error) {
                if (!error) {
                    photo.likesCount--;
                    photo.isLiked = NO;
                    cell.photoLikeCount.text = [NSString stringWithFormat:@"%d", (int)photo.likesCount];
                }
            }];
        }
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"In order to like or comment on a photo, you'll need to grant this app permission to post to Facebook. We will NEVER submit anything without your permission. Do you wish to continue?" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
            [loginManager logInWithPublishPermissions:@[@"publish_actions"]
                                   fromViewController:self
                                              handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                                  if (error) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Something went wrong.  Please check your internet and try again." preferredStyle:UIAlertControllerStyleAlert];
                                                          UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                                                          [alertController addAction:okAction];
                                                          [self presentViewController:alertController animated:YES completion:nil];
                                                      });
                                                  }
                                              }];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
    }
    
}

- (void)refreshButtonTapped:(UIButton *)sender {
    [self showProgressHudWithText:nil];
    self.refreshAlbumPhotosButton.hidden = YES;
    [[FiftyTwoFrames sharedInstance] requestLatestWeeklyThemeAlbumWithCompletionBlock:^(FTFAlbum *album, NSError *error, BOOL finishedPaging) {
        self.albumToDisplay = album;
        [self populateAlbumPhotosResultsWithPhotos:album.photos error:error finishedPaging:finishedPaging];
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return [gestureRecognizer locationInView:self.view].x < 35;
}

- (void)panReceivedInView:(UIPanGestureRecognizer *)sender {
    [self.frostedViewController panGestureRecognized:sender];
}

#pragma mark - UIStoryboardSegue

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    
}

#pragma mark - FTFFiltersViewControllerDelegate

- (void)filtersViewControllerDidSaveFilters:(NSDictionary *)filtersDictionary {
    [self showProgressHudWithText:@"Applying filters"];
    [[FiftyTwoFrames sharedInstance] requestAlbumPhotosWithFilters:filtersDictionary albumId:self.albumToDisplay.albumID completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        _finishedPaging = finishedPaging;
        if (!finishedPaging) _morePhotosToLoad = YES;
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.userInfo[@"message"] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:action];
                [self presentViewController:alertController animated:YES completion:nil];
            });
            
            return;
        }
        self.searchTerm = filtersDictionary[@"searchTerm"];
        [self setFilterIconEnabled:YES];
        self.gridPhotos = photos;
        _showingFilteredResults = YES;
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        });
        self.collectionReusableView.hidden = YES;
    }];
}

- (void)filtersViewControllerDidResetFilters {
    [self updateUIForResetFilters];
}

- (void)setFilterIconEnabled:(BOOL)enabled {
    UIImage *filterImage = enabled ? [UIImage imageNamed:@"filter-enabled"] : [UIImage imageNamed:@"filter-disabled"];
    UIColor *tintColor = enabled ? [UIColor orangeColor] : [UIColor whiteColor];

    [self.searchButton setImage:filterImage];
    self.searchButton.tintColor = tintColor;
}

- (void)updateUIForResetFilters {
    [self setFilterIconEnabled:NO];
    if (_showingFilteredResults) {
        _showingFilteredResults = NO;
        _finishedPaging = _unfilteredPhotosFinishedPaging;
        self.searchTerm = nil;
        self.collectionReusableView.hidden = NO;
        self.gridPhotos = self.cachedAlbumPhotos;
        [self.collectionView reloadData];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        _morePhotosToLoad = YES;
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.gridPhotos.count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[FTFCollectionViewCell class]]) {
        FTFCollectionViewCell *ftfCell = (FTFCollectionViewCell *)cell;
        FTFImage *photo = self.gridPhotos[indexPath.row];
        
        ftfCell.photoLikeCount.text = [NSString stringWithFormat:@"%ld", (long)photo.likesCount];
        
        if (photo.photographerName != nil) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:photo.photographerName];
            if (self.searchTerm != nil) {
                NSRange range = [photo.photographerName rangeOfString:self.searchTerm];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
            }
            ftfCell.photographerName.attributedText = attributedString;
        } else {
            ftfCell.photographerName.text = @"";
        }
        [ftfCell.likeButton setImage:[UIImage imageNamed:photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"] forState:UIControlStateNormal];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"collectionViewCell";
    
    FTFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                     forIndexPath:indexPath];
    
    FTFImage *photoAtIndex = self.gridPhotos[indexPath.row];
    if (photoAtIndex) {
        [MBProgressHUD hideHUDForView:self.collectionView animated:NO];
    }

//    if (indexPath.row == self.gridPhotos.count - 4) {
//        _morePhotosToLoad = YES;
//    }
    
    [cell updateCellsForLayout:self.currentLayout];
    cell.thumbnailView.backgroundColor = [UIColor darkGrayColor];

    [cell.thumbnailView setImageWithURL:photoAtIndex.smallPhotoURL
                       placeholderImage:nil
                                options:SDWebImageRetryFailed
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  NSLog(@"Cache type:  %ld", (long)cacheType);
                                    if (cacheType == SDImageCacheTypeNone) {
                                        CATransition *t = [CATransition animation];
                                        t.duration = 0.17;
                                        t.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                        t.type = kCATransitionFade;
                                        [cell.thumbnailView.layer addAnimation:t forKey:@"ftf"];
                                    }
                                    cell.thumbnailView.backgroundColor = [UIColor blackColor];
                                    cell.thumbnailView.image = image;
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self pushPhotoBrowserAtPhotoIndex:indexPath.row];

}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (![kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return nil;
    } else {
        self.collectionReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        
        if (_finishedPaging || !self.gridPhotos.count || _showingFilteredResults) {
            self.collectionReusableView.spinner.hidden = YES;
        } else {
            self.collectionReusableView.spinner.hidden = NO;
            [self.collectionReusableView.spinner startAnimating];
        }
    }
    
    return self.collectionReusableView;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
//    return CGSizeMake(0.0f, 0.0f);
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(50.0f, 50.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewLayout == self.gridLayout) {
        FTFImage *photo = self.gridPhotos[indexPath.row];
        return photo.smallPhotoSize;
    }
    
    return self.listLayout.itemSize;
}

#pragma mark - MWPhotoBrowser

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.gridPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    FTFImage *photo = self.gridPhotos[index];
    return [photo browserPhotoWithSize:FTFImageSizeLarge];
}

- (void)pushPhotoBrowserAtPhotoIndex:(NSInteger)index {
    [self setUpPhotoBrowserForTappedPhotoAtRow];
    [self.photoBrowser setCurrentPhotoIndex:index];
    [self.navigationController pushViewController:self.photoBrowser animated:YES];
}

- (void)setUpPhotoBrowserForTappedPhotoAtRow {
    self.photoBrowser = [[FTFPhotoBrowserViewController alloc]
                         initWithDelegate:self];
    if (albumSelectionChanged || ![self.gridPhotos count] || _didPageNextBatchOfPhotos) {
        albumSelectionChanged = NO;
    }
    self.photoBrowser.albumPhotos = self.gridPhotos;
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    FTFImage *photo = self.gridPhotos[index];
    MWPhoto *browserPhoto = [photo browserPhotoWithSize:FTFImageSizeLarge];
    FTFCustomCaptionView *captionView = [[FTFCustomCaptionView alloc] initWithPhoto:browserPhoto];
    return captionView;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    if (self.gridPhotos.count - index < 4 && !_finishedPaging) {
        [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosFromFilteredResults:_showingFilteredResults withCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
            _finishedPaging = finishedPaging;
            NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
            [albumPhotos addObjectsFromArray:photos];
            self.gridPhotos = [albumPhotos copy];
            self.photoBrowser.albumPhotos = self.gridPhotos;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.photoBrowser reloadData];
                [self.collectionView reloadData];
            });
            
            _didPageNextBatchOfPhotos = YES;
            _morePhotosToLoad = YES;
        }];
    }
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if (self.photoBrowser != nil && viewController == self) {
        NSInteger currentIndex = self.photoBrowser.currentIndex;
        _layoutDidChange = YES;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:currentIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
        _layoutDidChange = NO;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -150;
    if(y > h + reload_distance) {
        if (self.gridPhotos && _morePhotosToLoad && !_layoutDidChange) {
            _morePhotosToLoad = NO;
            NSLog(@"Grid hit the bottom");
            // if we reset filters, we need to only load more photos if our cached _finishedPaging is true

            if (!_finishedPaging) {
                if (![self.navBarAlbumTitle.text isEqualToString:@"Loading more photos..."]) {
                    [UIView animateWithDuration:0.5 animations:^{
                        self.navigationItem.titleView.alpha = 0.0;
                        [self.navBarAlbumTitle setAttributedTitleWithText:@"Loading more photos..."];
                        self.navigationItem.titleView.alpha = 1.0;
                    }];
                }
                [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosFromFilteredResults:_showingFilteredResults withCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                    NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
                    [albumPhotos addObjectsFromArray:photos];
                    NSInteger gridPhotosCount = self.gridPhotos.count;
                    self.gridPhotos = [albumPhotos copy];
                    NSLog(@"Paged more photos:  Now %ld photos showing", self.gridPhotos.count);
                    _finishedPaging = finishedPaging;
                    if (!_showingFilteredResults) {
                        // update
                        _unfilteredPhotosFinishedPaging = finishedPaging;
                        self.cachedAlbumPhotos = [self.gridPhotos copy];
                    }
                    [self.collectionView performBatchUpdates:^{
                        NSMutableArray *indexPaths = [NSMutableArray new];
                        for (NSInteger i = gridPhotosCount; i < gridPhotosCount + photos.count; i++) {
                            NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                            [indexPaths addObject:ip];
                        }
                        [self.collectionView insertItemsAtIndexPaths:indexPaths];
                        
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.4 animations:^{
                            self.navigationItem.titleView.alpha = 0.0;
                            [self.navBarAlbumTitle setAttributedTitleWithText:self.albumToDisplay.name];
                            self.navigationItem.titleView.alpha = 1.0;
                            _morePhotosToLoad = YES;
                        }];
                    }];
                }];
            }
        }
    }
    _layoutDidChange = NO;
}

-(void)postLayoutNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"LayoutDidChange"
     object:self userInfo:userInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

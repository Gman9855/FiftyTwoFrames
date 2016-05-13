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
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FTFPhotoCollectionGridViewController () <CHTCollectionViewDelegateWaterfallLayout, UINavigationControllerDelegate, MWPhotoBrowserDelegate, UISearchBarDelegate>

@property (nonatomic, strong) FTFCollectionReusableView *collectionReusableView;
@property (nonatomic, strong) UILabel *navBarTitle;
@property (nonatomic, strong) FTFNavigationBarAlbumTitle *navBarAlbumTitle;
@property (nonatomic, strong) FTFListLayout *listLayout;
@property (nonatomic, strong) CHTCollectionViewWaterfallLayout *gridLayout;
@property (nonatomic, strong) UICollectionViewLayout *currentLayout;
@property (nonatomic, assign) BOOL shouldReloadData;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *layoutToggleButton;@property (nonatomic, strong) FTFAlbumSelectionMenuViewController *albumSelectionMenuViewController;
@property (nonatomic, strong) UINavigationController *albumSelectionMenuNavigationController;
@property (nonatomic, strong) FTFPhotoBrowserViewController *photoBrowser;
@property (nonatomic, strong) FTFAlbum *albumToDisplay;
@property (nonatomic, strong) FTFAlbumCollection *photoWalksAlbums;
@property (nonatomic, strong) FTFAlbumCollection *miscellaneousSubmissionsAlbums;
@property (nonatomic, strong) NSArray *browserPhotos;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *hostingView;
@property (nonatomic, strong) NSArray *thumbnailPhotosForGrid;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIButton *refreshAlbumPhotosButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *gridButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *albumInfoButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButton;

@end

static NSString * const reuseIdentifier = @"photo";
BOOL albumSelectionChanged = NO;
BOOL _morePhotosToLoad = NO;
BOOL didLikePhotoFromBrowser = NO;

@implementation FTFPhotoCollectionGridViewController {
    BOOL _albumSelectionChanged;
    BOOL _morePhotosToLoad;
    BOOL _finishedPaging;
    BOOL _didUpdateCells;
    BOOL _layoutDidChange;
    BOOL _didPageNextBatchOfPhotos;
    BOOL _isCurrentlyLoadingMorePhotos;
}

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

- (FTFNavigationBarAlbumTitle *)navBarAlbumTitle {
    if (!_navBarAlbumTitle) {
        _navBarAlbumTitle = [[FTFNavigationBarAlbumTitle alloc] initWithTitle:@"52Frames"];
    }
    
    return _navBarAlbumTitle;
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

- (void)awakeFromNib {
    [self addObserver:self forKeyPath:@"gridPhotos" options:NSKeyValueObservingOptionNew context:NULL];
    self.shouldReloadData = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateForAlbumWithNoPaging:)
                                                 name:@"albumDoesNotNeedToBePagedNotification"
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.showsCancelButton = YES;
    self.searchBar.translucent = YES;
    self.searchBar.delegate = self;
    
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
    FTFCollectionViewCell *cell = (FTFCollectionViewCell *)[self.collectionView cellForRowAtIndexPath:ip];
    [self handlePhotoLikeWithCell:cell andPhoto:photoAtIndex];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"gridPhotos"]) {
        if (self.shouldReloadData) {
            [self.collectionView reloadData];
        }
    }
}

- (void)showProgressHudWithText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    if (![text isEqualToString:@""]) {
        hud.labelText = text;
    }
    
    //    [hud setCenter:[self.view convertPoint:self.view.center fromView:self.view.superview]];
    //    [hud setCenter:CGPointMake(self.view.bounds.size.height/2, self.view.bounds.size.width/2)];
}

//- (void)albumSelectionChanged:(NSNotification *)notification {
//    _albumSelectionChanged = YES;
//    _finishedPaging = NO;
//    if (self.gridPhotos) {
//        NSIndexPath *firstIndexPathInCollectionView = [NSIndexPath indexPathForItem:0 inSection:0];
//        [self.collectionView scrollToItemAtIndexPath:firstIndexPathInCollectionView
//                                    atScrollPosition:UICollectionViewScrollPositionTop
//                                            animated:NO];
//    }
//    
//    _albumSelectionChanged = NO;
//}

- (void)albumSelectionChanged:(NSNotification *)notification {
    self.refreshAlbumPhotosButton.hidden = YES;
    self.collectionView.userInteractionEnabled = NO;
    self.gridButton.enabled = NO;
    self.albumInfoButton.enabled = NO;
    albumSelectionChanged = YES;
    _morePhotosToLoad = NO;
    [self showProgressHudWithText:nil];
    [self.photoBrowser setCurrentPhotoIndex:0];
    
    self.albumToDisplay = [notification.userInfo objectForKey:@"selectedAlbum"];
    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                          completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                                                              [self populateAlbumPhotosResultsWithPhotos:photos error:error finishedPaging:finishedPaging];
                                                          }];
}

- (void)updateForAlbumWithNoPaging:(NSNotification *)notification {
    _finishedPaging = YES;
}

- (void)populateAlbumPhotosResultsWithPhotos:(NSArray *)photos
                                       error:(NSError *)error
                              finishedPaging: (BOOL)finishedPaging {
    _finishedPaging = finishedPaging;
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
        if (_finishedPaging) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"albumDoesNotNeedToBePagedNotification" object:nil];
        }
        [self.collectionView reloadData];
        
//        self.settingsButton.enabled = YES;
        self.gridButton.enabled = YES;
        self.albumInfoButton.enabled = YES;
        NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
        
        [self.collectionView scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        
        [UIView animateWithDuration:1.5 animations:^{
            self.navigationItem.titleView.alpha = 0.0;
            if ([self.albumToDisplay.name containsString:@":"]) {
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:self.albumToDisplay.name];
                NSArray *words = [self.albumToDisplay.name componentsSeparatedByString:@": "];
                NSString *albumName = [words firstObject];
                NSRange range = [self.albumToDisplay.name rangeOfString:albumName];
                range.length++;
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
                [self.navBarAlbumTitle setAttributedTitleWithText:self.albumToDisplay.name];
            } else {
                [self.navBarAlbumTitle setAttributedTitleWithText:self.albumToDisplay.name];
            }
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
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSearchBar)]];

    [UIView animateWithDuration:0.1 animations:^{
        NSMutableArray *navBarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
        [navBarButtons removeObject:self.searchButton];
        [self.navigationItem setRightBarButtonItems:navBarButtons animated:YES];
        self.navBarAlbumTitle.alpha = 0.0;
    } completion:^(BOOL finished) {
        // remove the search button
        self.navigationItem.rightBarButtonItem = nil;
        // add the search bar (which will start out hidden).
        self.navigationItem.titleView = self.searchBar;
        self.searchBar.alpha = 0.0;
        [self.searchBar becomeFirstResponder];
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.searchBar.alpha = 1.0;
                         } completion:nil];
    }];
}

- (IBAction)toggleLayout:(UIBarButtonItem *)sender {
    _layoutDidChange = YES;
    UICollectionViewLayout *layout;
    NSString *layoutType;
    NSString *toolbarIconImageName;
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        layout = self.gridLayout;
        layoutType = @"grid";
        self.navigationItem.rightBarButtonItem.title = @"List";
        toolbarIconImageName = @"DefaultStyle";
    } else {
        layout = self.listLayout;
        layoutType = @"list";
        self.navigationItem.rightBarButtonItem.title = @"Grid";
        toolbarIconImageName = @"Grid";
    }
    self.currentLayout = layout;
    self.layoutToggleButton.image = [UIImage imageNamed:toolbarIconImageName];
    
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
    albumDescriptionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [albumDescriptionVC setModalPresentationStyle:UIModalPresentationOverCurrentContext];
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

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    
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
        
        if (![photo.photoDescription isEqual:[NSNull null]]) {
            ftfCell.photographerName.text = photo.photographerName;
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

    if (indexPath.row == self.gridPhotos.count - 7) {
        _morePhotosToLoad = YES;
    }
    
    [cell updateCellsForLayout:self.currentLayout];
    
    [cell.thumbnailView setImageWithURL:photoAtIndex.smallPhotoURL
                       placeholderImage:[UIImage imageNamed:@"placeholder"]
                                options:SDWebImageRetryFailed
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    if (cacheType == SDImageCacheTypeNone || cacheType == SDImageCacheTypeDisk) {
                                        CATransition *t = [CATransition animation];
                                        t.duration = 0.12;
                                        t.type = kCATransitionFade;
                                        [cell.thumbnailView.layer addAnimation:t forKey:@"ftf"];
                                    }

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
        
        if (_finishedPaging || !self.gridPhotos.count) {
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
    return self.browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.browserPhotos.count) {
        return [self.browserPhotos objectAtIndex:index];
    }
    return nil;
}

- (void)pushPhotoBrowserAtPhotoIndex:(NSInteger)index {
    [self setUpPhotoBrowserForTappedPhotoAtRow];
    [self.photoBrowser setCurrentPhotoIndex:index];
    [self.navigationController pushViewController:self.photoBrowser animated:YES];
}

- (void)setUpPhotoBrowserForTappedPhotoAtRow {
    self.photoBrowser = [[FTFPhotoBrowserViewController alloc]
                         initWithDelegate:self];
    if (albumSelectionChanged || ![self.browserPhotos count] || _didPageNextBatchOfPhotos) {
        self.browserPhotos = [self photosCompatibleForUseInPhotoBrowserWithSize:FTFImageSizeLarge];
        //repopulate browserPhotos with newly selected album
        albumSelectionChanged = NO;
    }
    self.photoBrowser.albumPhotos = self.gridPhotos;
}

- (NSArray *)photosCompatibleForUseInPhotoBrowserWithSize:(FTFImageSize)size {
    NSMutableArray *photos = [NSMutableArray new];
    for (FTFImage *image in self.gridPhotos) {
        [photos addObject:[image browserPhotoWithSize:size]];
    }
    
    return [photos copy];
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [[self photosCompatibleForUseInPhotoBrowserWithSize:FTFImageSizeLarge] objectAtIndex:index];
    FTFCustomCaptionView *captionView = [[FTFCustomCaptionView alloc] initWithPhoto:photo];
    return captionView;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    if (self.browserPhotos.count - index < 4 && !_finishedPaging) {
        [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosWithCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
            _finishedPaging = finishedPaging;
            NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
            [albumPhotos addObjectsFromArray:photos];
            self.gridPhotos = [albumPhotos copy];
            self.browserPhotos = [self photosCompatibleForUseInPhotoBrowserWithSize:FTFImageSizeLarge];
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
        NSIndexPath *ip = [NSIndexPath indexPathForRow:currentIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
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
    if(y > h + reload_distance && self.gridPhotos && _morePhotosToLoad && !_layoutDidChange) {
        _morePhotosToLoad = NO;
        NSLog(@"Grid hit the bottom");
        if (!_finishedPaging) {
            if (![self.navBarAlbumTitle.text isEqualToString:@"Loading more photos..."]) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.navigationItem.titleView.alpha = 0.0;
                    [self.navBarAlbumTitle setAttributedTitleWithText:@"Loading more photos..."];
                    self.navigationItem.titleView.alpha = 1.0;
                }];
            }
            
            [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosWithCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                _finishedPaging = finishedPaging;
                
                NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
                [albumPhotos addObjectsFromArray:photos];
                self.shouldReloadData = NO;
                NSInteger gridPhotosCount = self.gridPhotos.count;
                self.gridPhotos = [albumPhotos copy];
                self.shouldReloadData = YES;
                
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
                    }];
                }];
                
                NSNumber *isFinishedPaging = [NSNumber numberWithBool:finishedPaging];
                NSDictionary *updatedAlbumPhotos = [NSDictionary dictionaryWithObjectsAndKeys:albumPhotos, @"albumPhotos", isFinishedPaging, @"finishedPaging", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"photoGridDidPageMorePhotosNotification"
                                                                    object:nil
                                                                  userInfo:updatedAlbumPhotos];
                _morePhotosToLoad = YES;
            }];
        }
    }
    _layoutDidChange = NO;
}

-(void)postLayoutNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"LayoutDidChange"
     object:self userInfo:userInfo];
}

-(void)changeLayout {
    _layoutDidChange = YES;
    UICollectionViewLayout *layout;
    NSString *layoutType;
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        layout = self.gridLayout;
        layoutType = @"grid";
        self.navigationItem.rightBarButtonItem.title = @"List";
    } else {
        layout = self.listLayout;
        layoutType = @"list";
        self.navigationItem.rightBarButtonItem.title = @"Grid";
    }
    
    self.currentLayout = layout;
    
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

#pragma mark UISearchBarDelegate methods
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self dismissSearchBar];
}

- (void)dismissSearchBar {
    [self.view removeGestureRecognizer:self.view.gestureRecognizers.firstObject];
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.searchBar.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^ {
            // unhide search button
            //            self.navigationItem.rightBarButtonItem = self.searchButton;
            NSMutableArray *navBarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
            if (![navBarButtons containsObject:self.searchButton]) {
                [navBarButtons addObject:self.searchButton];
                [self.navigationItem setRightBarButtonItems:navBarButtons animated:YES];
            }
            self.navigationItem.titleView = self.navBarAlbumTitle;
            self.navBarAlbumTitle.alpha = 1.0;
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"gridPhotos" context:NULL];
}

@end

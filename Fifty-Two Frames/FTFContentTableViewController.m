//
//  FTFContentTableViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/2/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFContentTableViewController.h"
#import "FTFTableViewCell.h"
#import "FTFActivityIndicatorCell.h"
#import "UIImageView+WebCache.h"
#import "FTFImage.h"
#import "FTFAlbumSelectionMenuViewController.h"
#import "MBProgressHUD.h"
#import "MWPhotoBrowser.h"
#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import "FTFPhotoBrowserViewController.h"
#import "FTFPhotoContainerViewController.h"
#import "FTFImage+MWPhotoAdditions.h"
#import "FTFPhotoCollectionGridViewController.h"
#import "FiftyTwoFrames.h"
#import "FTFAlbumCategoryCollection.h"
#import "FTFAlbumDescriptionViewController.h"
#import "FTFCustomCaptionView.h"

@interface FTFContentTableViewController () <UINavigationControllerDelegate, MWPhotoBrowserDelegate, FTFPhotoCollectionGridViewControllerDelegate>

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
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (nonatomic, strong) NSArray *browserPhotos;
@property (nonatomic, strong) UILabel *navBarTitle;
@property (nonatomic, strong) NSArray *albumPhotos;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *hostingView;
@property (nonatomic, strong) NSArray *thumbnailPhotosForGrid;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

static NSString * const reuseIdentifier = @"photo";
BOOL albumSelectionChanged = NO;
BOOL _morePhotosToLoad = NO;

@implementation FTFContentTableViewController {
    BOOL _didPageNextBatchOfPhotos;
    BOOL _finishedPaging;
}

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

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.photoGrid = [self.storyboard instantiateViewControllerWithIdentifier:@"grid"];
    self.photoGrid.delegate = self;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.frame = CGRectMake(0, 0, 200, 12);
    self.spinner.hidden = YES;
    self.tableView.tableFooterView = self.spinner;
    
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
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(updateLikeCountLabel:)
                                                name:didPressLikeNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAlbumPhotosWithPagedPhotosFromPhotoGrid:) name:@"photoGridDidPageMorePhotosNotification"
                                               object:nil];
}

- (void)updateLikeCountLabel:(NSNotification *)notification {
    int indexOfPhoto = [notification.object intValue];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:indexOfPhoto inSection:0];
    FTFImage *photoAtIndex = self.albumPhotos[indexOfPhoto];
    FTFTableViewCell *cell = (FTFTableViewCell *)[self.tableView cellForRowAtIndexPath:ip];
    [self handlePhotoLikeWithCell:cell andPhoto:photoAtIndex];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
}

- (void)setUpNavigationBarTitle {
    self.navBarTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 85)];
    self.navBarTitle.textAlignment = NSTextAlignmentCenter;
    self.navBarTitle.textColor = [UIColor whiteColor];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:@"52Frames"];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:NSMakeRange(0,2)];
    [self.navBarTitle setAttributedText:attributedString];
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
    
    FTFAlbum *mostCurrentWeeklyAlbum = self.weeklyThemeAlbums.albums.firstObject;
    albumSelectionMenuVC.selectedAlbumCollection = [albumSelectionMenuVC albumsForGivenYear:mostCurrentWeeklyAlbum.yearCreated
                                          fromAlbumCollection:self.weeklyThemeAlbums];
    albumSelectionMenuVC.selectedAlbumYear = mostCurrentWeeklyAlbum.yearCreated;
    albumSelectionMenuVC.yearButton.title = mostCurrentWeeklyAlbum.yearCreated;
    
    self.albumToDisplay = mostCurrentWeeklyAlbum;
    
    [[FiftyTwoFrames sharedInstance] requestUserWithCompletionBlock:^(FTFUser *user) {
        [[FiftyTwoFrames sharedInstance] requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                               completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                                                                   
                                                                   _finishedPaging = finishedPaging;
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       [self populateAlbumPhotosResultsWithPhotos:photos error:error];
                                                                   });
                                                               }];
    }];
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    self.tableView.userInteractionEnabled = NO;
    albumSelectionChanged = YES;
    _morePhotosToLoad = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.photoBrowser setCurrentPhotoIndex:0];
    
    self.albumToDisplay = [notification.userInfo objectForKey:@"selectedAlbum"];
    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                          completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                                                              
                                                              _finishedPaging = finishedPaging;
                                                              [self populateAlbumPhotosResultsWithPhotos:photos error:error];
    }];
}

- (void)updateAlbumPhotosWithPagedPhotosFromPhotoGrid:(NSNotification *)notification {
    self.albumPhotos = [notification.userInfo objectForKey:@"albumPhotos"];
    NSNumber *finishedPaging = [notification.userInfo objectForKey:@"finishedPaging"];
    NSInteger num = [finishedPaging integerValue];
    if (num == 1) {
        _finishedPaging = YES;
    }
    _didPageNextBatchOfPhotos = YES;
    [self.tableView reloadData];
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
        if (_finishedPaging) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"albumDoesNotNeedToBePagedNotification" object:nil];
        }
        [self.tableView reloadData];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
        self.tableView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:1.5 animations:^{
            self.navigationItem.titleView.alpha = 0.0;
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:self.albumToDisplay.name];
            NSArray *words = [self.albumToDisplay.name componentsSeparatedByString:@": "];
            NSString *albumName = [words firstObject];
            NSRange range = [self.albumToDisplay.name rangeOfString:albumName];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
            [self.navBarTitle setAttributedText:attributedString];
            self.navigationItem.titleView.alpha = 1.0;
        }];
    
        _morePhotosToLoad = YES;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Sorry, no photos found for this album"
                                                      delegate:self
                                           cancelButtonTitle:@"Okay"
                                            otherButtonTitles:nil];
        [alert show];
        });
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
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([cell isKindOfClass:[FTFTableViewCell class]]) {
        FTFTableViewCell *ftfCell = (FTFTableViewCell *)cell;
        FTFImage *photo = self.albumPhotos[indexPath.row];
        
        ftfCell.likesCountLabel.text = [NSString stringWithFormat:@"%ld", (long)photo.likesCount];
        
        if (![photo.photoDescription isEqual:[NSNull null]]) {
            ftfCell.photographerLabel.text = photo.photographerName;
        } else {
            ftfCell.photographerLabel.text = @"";
        }
        [ftfCell.likeButton setImage:[UIImage imageNamed:photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"] forState:UIControlStateNormal];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.albumPhotos count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return self.spinner;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FTFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    FTFImage *photo = self.albumPhotos[indexPath.row];
    
    [cell.photo setImageWithURL:photo.largePhotoURL placeholderImage:nil
                        options:SDWebImageRetryFailed
                       progress:nil
                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                          if (cacheType == SDImageCacheTypeNone || cacheType == SDImageCacheTypeDisk) {
                              CATransition *t = [CATransition animation];
                              t.duration = 0.15;
                              t.type = kCATransitionFade;
                              [cell.photo.layer addAnimation:t forKey:@"ftf"];
                          }
                          cell.photo.image = image;
                          cell.selectionStyle = UITableViewCellSelectionStyleNone;
                          
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self pushPhotoBrowserAtPhotoIndex:indexPath.row];
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
    self.photoBrowser.albumPhotos = self.albumPhotos;
}

- (NSArray *)photosCompatibleForUseInPhotoBrowserWithSize:(FTFImageSize)size {
    NSMutableArray *photos = [NSMutableArray new];
    for (FTFImage *image in self.albumPhotos) {
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
            NSMutableArray *albumPhotos = [self.albumPhotos mutableCopy];
            [albumPhotos addObjectsFromArray:photos];
            self.albumPhotos = [albumPhotos copy];
            self.browserPhotos = [self photosCompatibleForUseInPhotoBrowserWithSize:FTFImageSizeLarge];
            self.photoBrowser.albumPhotos = self.albumPhotos;
            self.photoGrid.gridPhotos = self.albumPhotos;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.photoBrowser reloadData];
                [self.tableView reloadData];
            });
            
            _didPageNextBatchOfPhotos = YES;
            _morePhotosToLoad = YES;
        }];
    }
}

#pragma mark - FTFPhotoCollectionGridViewController Delegate

- (void)photoCollectionGridDidSelectPhotoAtIndex:(NSInteger)index {
    [self pushPhotoBrowserAtPhotoIndex:index];
}

#pragma mark - Actions

- (IBAction)settingsButtonTapped:(UIBarButtonItem *)sender;
{
    [self presentViewController:self.albumSelectionMenuNavigationController animated:true completion:nil];
}

- (IBAction)likeIconTapped:(UIButton *)sender {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.2;
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    anim.removedOnCompletion = YES;
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1.0)];
    [sender.layer addAnimation:anim forKey:nil];
    
    // Find which cell the like came from
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    
    FTFImage *photo = self.albumPhotos[indexPath.row];
    FTFTableViewCell *cell = (FTFTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [self handlePhotoLikeWithCell:cell andPhoto:photo];
}

- (void)handlePhotoLikeWithCell:(FTFTableViewCell *)cell andPhoto:(FTFImage *)photo {
    [cell.likeButton setImage:[UIImage imageNamed:!photo.isLiked ? @"ThumbUpFilled" : @"ThumbUp"] forState:UIControlStateNormal];
    if (!photo.isLiked) {
        [[FiftyTwoFrames sharedInstance] publishPhotoLikeWithPhotoID:photo.photoID completionBlock:^(NSError *error) {
            if (!error) {
                photo.likesCount++;
                photo.isLiked = YES;
                cell.likesCountLabel.text = [NSString stringWithFormat:@"%d", (int)photo.likesCount];
            }
        }];
    } else {
        [[FiftyTwoFrames sharedInstance] deletePhotoLikeWithPhotoID:photo.photoID completionBlock:^(NSError *error) {
            if (!error) {
                photo.likesCount--;
                photo.isLiked = NO;
                cell.likesCountLabel.text = [NSString stringWithFormat:@"%d", (int)photo.likesCount];
            }
        }];
    }
}

- (void)_dismissButtonTapped:(id)sender;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)infoButtonTapped:(UIBarButtonItem *)sender;
{
    FTFAlbumDescriptionViewController *albumDescriptionVC = (FTFAlbumDescriptionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"albumDescriptionVC"];
    albumDescriptionVC.album = self.albumToDisplay;
    albumDescriptionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [albumDescriptionVC setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController:albumDescriptionVC animated:YES completion:nil];
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

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -10;
    if(y > h + reload_distance && _morePhotosToLoad && self.albumPhotos) {
        NSLog(@"hit bottom of tableView");
        _morePhotosToLoad = NO;
        if (!_finishedPaging) {
            self.spinner.hidden = NO;
            [self.spinner startAnimating];
            [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosWithCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                _finishedPaging = finishedPaging;
                NSMutableArray *albumPhotos = [self.albumPhotos mutableCopy];
                [albumPhotos addObjectsFromArray:photos];
                self.albumPhotos = [albumPhotos copy];
                self.photoGrid.gridPhotos = self.albumPhotos;
                [self.tableView reloadData];
                
                [self.spinner stopAnimating];
                self.spinner.hidden = YES;
                
                _didPageNextBatchOfPhotos = YES;
                _morePhotosToLoad = YES;
            }];
        }
    }
}

@end

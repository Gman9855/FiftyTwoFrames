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

@interface FTFContentTableViewController () <UINavigationControllerDelegate, MWPhotoBrowserDelegate, FTFAlbumSelectionMenuViewControllerDelegate, FTFPhotoCollectionGridViewControllerDelegate>

@property (nonatomic, strong) FTFAlbumSelectionMenuViewController *albumSelectionMenuViewController;
@property (nonatomic, strong) FTFPhotoBrowserViewController *photoBrowser;
@property (nonatomic, strong) FTFPhotoCollectionGridViewController *photoGrid;
@property (nonatomic, strong) FTFAlbumCollection *photoAlbumCollection;
@property (nonatomic, strong) FTFAlbum *albumToDisplay;
@property (nonatomic, strong) NSArray *weeklyThemeAlbums;
@property (nonatomic, strong) NSArray *photoWalksAlbums;
@property (nonatomic, strong) NSArray *miscellaneousSubmissionsAlbums;
@property (nonatomic, strong) UINavigationController *albumSelectionMenuNavigationController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, strong) NSArray *browserPhotos;
@property (nonatomic, assign) NSUInteger indexOfPhoto;
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

    [[FiftyTwoFrames sharedInstance] requestAlbumCollectionWithCompletionBlock:^(FTFAlbumCollection *albumCollection,
                                                                                 NSError *error) {
        if (error) {
            // Present alert
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

- (IBAction)refreshTableView:(id)sender {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = NO;
}

- (IBAction)infoButtonTapped:(UIBarButtonItem *)sender {

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

- (void)retrievedAlbumCollection {
    self.weeklyThemeAlbums = [self.photoAlbumCollection albumsForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    
    FTFAlbumSelectionMenuViewController *pocvc = (FTFAlbumSelectionMenuViewController *)[self.albumSelectionMenuNavigationController topViewController];
    pocvc.weeklySubmissions = [self.photoAlbumCollection albumsForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    pocvc.photoWalks = [self.photoAlbumCollection albumsForCategory:FTFAlbumCollectionCategoryPhotoWalks];
    pocvc.miscellaneousAlbums = [self.photoAlbumCollection albumsForCategory:FTFAlbumCollectionCategoryMiscellaneous];
    
    FTFAlbum *album = [self.weeklyThemeAlbums firstObject];
    pocvc.selectedAlbumCollection = [pocvc albumsForGivenYear:album.yearCreated
                                          fromAlbumCollection:self.weeklyThemeAlbums];
    pocvc.selectedAlbumYear = album.yearCreated;
    pocvc.yearButton.title = album.yearCreated;
    [pocvc.tableView reloadData];
    [MBProgressHUD hideHUDForView:pocvc.tableView animated:YES];
    self.albumToDisplay = [self.weeklyThemeAlbums firstObject];
    
    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                          completionBlock:^(NSArray *photos, NSError *error) {
                                                              
            [self populateAlbumPhotosResultsWithPhotos:photos error:error];
    }];

}

- (void)albumSelectionChanged:(NSNotification *)notification {
    albumSelectionChanged = YES;
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.photoGrid.gridPhotos = nil;
    
    self.albumToDisplay = [notification.userInfo objectForKey:@"selectedAlbum"];
    [[FiftyTwoFrames sharedInstance]requestAlbumPhotosForAlbumWithAlbumID:self.albumToDisplay.albumID
                                                          completionBlock:^(NSArray *photos, NSError *error) {
                                                              
            [self populateAlbumPhotosResultsWithPhotos:photos error:error];
    }];
}

- (void)populateAlbumPhotosResultsWithPhotos:(NSArray *)photos error:(NSError *)error {
    if (error) {
        [MBProgressHUD hideHUDForView:self.tableView animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"An error occured trying to grab this album's photos"
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([photos count]) {
        self.albumPhotos = photos;
        self.photoGrid.gridPhotos = photos;
        [self.tableView reloadData];
        
        [UIView animateWithDuration:1.5 animations:^{
            self.navigationItem.titleView.alpha = 0.0;
            self.navBarTitle.text = self.albumToDisplay.name;
            self.navigationItem.titleView.alpha = 1.0;
        }];
        
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
        [MBProgressHUD hideHUDForView:self.tableView animated:NO];
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

#pragma mark - Table view data source

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
    if (![photo.photoLikes isEqual:[NSNull null]]) {
        ftfCell.likesCountLabel.text = [NSString stringWithFormat:@"%d", [photo.photoLikes count]];
    }
    if (![photo.photoDescription isEqual:[NSNull null]]) {
        ftfCell.descriptionLabel.text = photo.photoDescription;
    } else {
        ftfCell.descriptionLabel.text = @"";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [photo requestImageWithSize:FTFImageSizeSmall
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

#pragma mark - MWPhotoBrowser Delegate

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

#pragma mark - Album Selection Menu VC Delegate

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

#pragma mark - Photo Collection Grid VC Delegate

- (void)photoCollectionGridDidSelectPhotoAtIndex:(NSInteger)index {
    [self pushPhotoBrowserAtPhotoIndex:index];
}

#pragma mark - Navigation

- (IBAction)settingsButtonTapped:(UIBarButtonItem *)sender;
{
    UIView *navigationView = self.navigationController.view;
    self.hostingView.frame = navigationView.bounds;
    self.hostingView.bounds = self.view.bounds;
    
    self.albumSelectionMenuNavigationController.view.frame = CGRectInset(self.hostingView.bounds, 15, 15);
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

- (IBAction)gridButtonTapped:(UIBarButtonItem *)sender {
//    CATransition *transition = [CATransition animation];
//    transition.duration = 0.5;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//    transition.type = kCATransitionFade;
//    transition.subtype = kCATransitionFade;
//    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController pushViewController:self.photoGrid animated:YES];
}

- (void)pushPhotoBrowserAtPhotoIndex:(NSInteger)index {
    [self setUpPhotoBrowserForTappedPhotoAtRow];
    [self.photoBrowser setCurrentPhotoIndex:index];
    [self.navigationController pushViewController:self.photoBrowser animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if (self.photoBrowser != nil && viewController == self) {
        NSInteger currentIndex = self.photoBrowser.currentIndex;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:currentIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
}

@end

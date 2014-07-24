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
#import "FTFPhotoViewController.h"
#import "FTFPopoverContentViewController.h"
#import "MWPhotoBrowser.h"
#import "MBProgressHUD.h"

@interface FTFContentTableViewController () <MWPhotoBrowserDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *weeklySubmissions;
@property (nonatomic, strong) NSArray *photoWalks;
@property (nonatomic, strong) NSArray *miscellaneousSubmissions;
@property (nonatomic, strong) FTFPopoverContentViewController *albumListViewController;
@property (nonatomic, strong) UINavigationController *navController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, strong) NSMutableArray *photosForDisplayInBrowser;
@property (nonatomic, strong) MWPhotoBrowser *browser;
@property (nonatomic, assign) NSUInteger indexOfPhoto;
@property (nonatomic, strong) UILabel *navBarTitle;


@end

static NSString * const reuseIdentifier = @"photo";
BOOL viewLoadedForFirstTime = NO;

@implementation FTFContentTableViewController

- (UINavigationController *)navController {
    if (!_navController) {
        _navController = [self.storyboard instantiateViewControllerWithIdentifier:@"popoverView"];
    }
    return _navController;
}

- (FTFPopoverContentViewController *)albumListViewController {
    if (!_albumListViewController) {
        
        UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"popoverView"];
        _albumListViewController = (FTFPopoverContentViewController *)navController.topViewController;
    }
    return _albumListViewController;
}

- (IBAction)refreshTableView:(id)sender {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
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
    
    [self setUpNavigationBarTitle];

    self.navigationController.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setUpActivityIndicator];
    
    viewLoadedForFirstTime = YES;   //load the latest weekly photos on first launch
    
    [self makeRequestForAlbumInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumSelectionChanged:)
                                                 name:@"albumSelectedNotification"
                                               object:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setUpNavigationBarTitle {
    self.navBarTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 85)];
    self.navBarTitle.textAlignment = NSTextAlignmentCenter;
    self.navBarTitle.text = @"Fifty-Two Frames";
    self.navBarTitle.textColor = [UIColor whiteColor];
    self.navBarTitle.font = [UIFont boldSystemFontOfSize:14];
    self.navBarTitle.numberOfLines = 2;
    //self.navBarTitle.lineBreakMode = NSLineBreak;
    self.navigationItem.titleView = self.navBarTitle;
}

- (void)setUpActivityIndicator {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading photos";
    hud.yOffset = -60;
}

- (IBAction)likeIconTapped:(id)sender {
    
}

- (void)makeRequestForAlbumInfo;
{
    [FBRequestConnection startWithGraphPath:@"/180889155269546?fields=albums.limit(10000).fields(name)"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              [self populateAlbumInfoArrays:result];
                          }];
}

- (void)populateAlbumInfoArrays:(id)fetchResult;
{
    NSDictionary *fr = fetchResult;
    NSArray *albumInfoDicts = [fr valueForKeyPath:@"albums.data"];
    NSPredicate *weekPredicate = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@)", @"week"];
    NSPredicate *photoWalkPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@ || name CONTAINS[cd] %@ || name CONTAINS[cd] %@)", @"photowalk", @"photo walk", @"photo-walk"];
    NSPredicate *orPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[weekPredicate, photoWalkPredicate]];
    NSPredicate *compoundPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:orPredicate];
    
    NSArray *miscellaneousAlbumNames = [albumInfoDicts filteredArrayUsingPredicate:compoundPredicate];
    NSArray *weekNames = [albumInfoDicts filteredArrayUsingPredicate:weekPredicate];
    NSArray *photoWalkNames = [albumInfoDicts filteredArrayUsingPredicate:photoWalkPredicate];

    NSSortDescriptor *createdDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:NO];
    self.weeklySubmissions = [weekNames sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    self.photoWalks = [photoWalkNames sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    self.miscellaneousSubmissions = [miscellaneousAlbumNames sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    
    if (viewLoadedForFirstTime) {
        NSDictionary *latestWeek = [self.weeklySubmissions firstObject];
        [self makeRequestForAlbumPhotos:latestWeek];
    }
    
    FTFPopoverContentViewController *poc = (FTFPopoverContentViewController *)self.navController.topViewController;
    poc.weeklySubmissions = self.weeklySubmissions;
    poc.photoWalks = self.photoWalks;
    poc.miscellaneousAlbums = self.miscellaneousSubmissions;
    
    viewLoadedForFirstTime = NO;
}

- (NSArray *)removeAlbumDuplicates:(NSArray *)albums {
    NSMutableArray *albumsFiltered = [[NSMutableArray alloc] init];    //This will be the array of groups you need
    NSMutableArray *albumNamesEncountered = [[NSMutableArray alloc] init]; //This is an array of group names seen so far
    
    NSString *name;        //Preallocation of group name
    for (NSDictionary *albumInfo in albums) {  //Iterate through all groups
        name = [albumInfo objectForKey:@"name"]; //Get the group name
        if ([albumNamesEncountered indexOfObject:name] == NSNotFound) {  //Check if this group name hasn't been encountered before
            [albumNamesEncountered addObject:name]; //Now you've encountered it, so add it to the list of encountered names
            [albumsFiltered addObject:albumInfo];   //And add the group to the list, as this is the first time it's encountered
        }
    }
    return [albumsFiltered copy];
}

- (void)makeRequestForAlbumPhotos:(NSDictionary *)albumInfo;
{
//    /180889155269546?fields=albums.limit(1).fields(photos.limit(200))
    id albumID = [albumInfo valueForKeyPath:@"id"];

    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=photos.limit(200)", albumID]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              [self populateUserPhotosArray:result];
                              
                              NSString *weekName = [albumInfo valueForKeyPath:@"name"];

                              [UIView animateWithDuration:1.7 animations:^{
                                  self.navigationItem.titleView.alpha = 0.0;
                                  self.navBarTitle.text = weekName;
                                  self.navigationItem.titleView.alpha = 1.0;
                              }];

                          }];
    
}

- (NSArray *)urlsFromPhotoArray:(NSArray *)array;
{
    NSString *largeImageURL = [self sourceOfImageData:array[0]];
    NSString *smallImageURL;
    for (NSDictionary *dict in array) {
        smallImageURL = largeImageURL;
        NSInteger imageHeight = [[dict valueForKeyPath:@"height"]intValue];
        if (imageHeight <= 500 && imageHeight >= 350) {
            smallImageURL = [self sourceOfImageData:dict];
            break;
        }
    }
    
    return [@[largeImageURL,
              smallImageURL] map:^id(id object, NSUInteger index) {
        return [NSURL URLWithString:object];
    }];
}

- (NSString *)sourceOfImageData:(NSDictionary *)data;
{
    return [data valueForKeyPath:@"source"];
}

- (void)populateUserPhotosArray:(id)fetchResult;
{
    NSDictionary *result = fetchResult;
    NSArray *imageCollections = [result valueForKeyPath:@"photos.data.images"];
    if (!imageCollections) {
        [MBProgressHUD hideHUDForView:self.tableView animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Shoot!" message:@"No photos found in this album" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSArray *photoDescriptionCollection = [result valueForKeyPath:@"photos.data.name"];
    NSArray *likesCollection = [result valueForKeyPath:@"photos.data.likes.data"];
    NSArray *commentsCollection = [result valueForKeyPath:@"photos.comments.data"];
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [imageCollections count]; i++) {
        NSArray *imageURLs = [self urlsFromPhotoArray:imageCollections[i]];
        FTFImage *image = [[FTFImage alloc] initWithImageURLs:imageURLs];
        image.photoDescription = photoDescriptionCollection[i];
        image.photoLikes = likesCollection[i];
        image.photoComments = commentsCollection[i];
        [objects addObject:image];
    }
    
    self.images = objects;
    [self.tableView reloadData];
    
    NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    NSDictionary *album = notification.userInfo;
    [self.navController dismissViewControllerAnimated:YES completion:nil];
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    [self makeRequestForAlbumPhotos:album];
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
    FTFImage *photo = self.images[indexPath.row];
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
        [photo requestImageWithSize:FTFImageSizeSmall completionBlock:^(UIImage *image, NSError *error, BOOL isCached) {
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
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    });
}

//- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
//{
//    FTFImage *image = self.images[indexPath.row];
//    [image cancel];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.images count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FTFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    return cell;
}

- (IBAction)settingsButtonTapped:(UIBarButtonItem *)sender;
{
    [self presentViewController:self.navController animated:YES completion:nil];
}

- (IBAction)menuButtonTapped:(UIBarButtonItem *)sender;
{

}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photosForDisplayInBrowser.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photosForDisplayInBrowser.count)
        return [self.photosForDisplayInBrowser objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    self.indexOfPhoto = index;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.photosForDisplayInBrowser = [NSMutableArray array];
    for (FTFImage *image in self.images) {
        NSURL *largePhotoURL = [image largePhotoURL];
        MWPhoto *photo = [MWPhoto photoWithURL:largePhotoURL];
        if (![image.photoDescription isEqual:[NSNull null]]) {
            photo.caption = image.photoDescription;
        }
        [self.photosForDisplayInBrowser addObject:photo];
    }
    
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    self.browser.displayActionButton = YES;
    self.browser.displaySelectionButtons = NO;
    self.browser.zoomPhotosToFill = NO;
    self.browser.displayNavArrows = YES;
    self.browser.hideControlsWhenDragging = NO;
    
    [self.browser setCurrentPhotoIndex:indexPath.row];
    
    [self.navigationController pushViewController:self.browser animated:YES];
}


#pragma mark - Navigation

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if (self.browser != nil && viewController == self) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:self.indexOfPhoto inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    FTFPhotoViewController *photoViewController = [segue destinationViewController];
//    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
//    if (indexPath) {
//        FTFImage *f = self.images[indexPath.row];
//        photoViewController.photo = f;
//        photoViewController.photoCount = [self.images count];
//    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end

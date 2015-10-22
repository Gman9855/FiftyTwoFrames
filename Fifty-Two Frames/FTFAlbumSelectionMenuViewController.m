//
//  FTFPopoverContentViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 7/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbumSelectionMenuViewController.h"
#import "WYPopoverController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "MBProgressHUD.h"
#import "FTFAlbum.h"
#import "FTFYearPopoverTableViewController.h"
#import "FiftyTwoFrames.h"
#import "UIImageView+WebCache.h"
#import "FTFAlbumSelectionMenuTableViewCell.h"
#import "FTFAlbumCollection.h"


@interface FTFAlbumSelectionMenuViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) FTFYearPopoverTableViewController *yearPopoverTableViewController;
@property (nonatomic, strong) WYPopoverController *popover;
@property (nonatomic, strong) UILabel *noAlbumslabel;
@property (nonatomic, strong) NSArray *albumThumbnailPhotos;

@end

static NSString * const reuseIdentifier = @"reuseIdentifier";

@implementation FTFAlbumSelectionMenuViewController

- (FTFYearPopoverTableViewController *)yearPopoverTableViewController {
    if (!_yearPopoverTableViewController) {
        _yearPopoverTableViewController = [[FTFYearPopoverTableViewController alloc] init];
    }
    return _yearPopoverTableViewController;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setSelectedAlbumCollection:(FTFAlbumCollection *)selectedAlbumCollection {
    _selectedAlbumCollection = selectedAlbumCollection;
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (self.navigationController.toolbarHidden && self.segmentedControl.hidden) {
        [UIView animateWithDuration:0.4 animations:^{
            self.navigationController.toolbarHidden = NO;
            self.segmentedControl.hidden = NO;
        }];
    }
    
    self.noAlbumslabel.hidden = YES;
    [self.tableView reloadData];

    if (!_selectedAlbumCollection.albums.count) {
        self.noAlbumslabel.center = [self.view convertPoint:self.view.center fromView:self.view.superview];
        self.noAlbumslabel.alpha = 0.0;
        self.noAlbumslabel.hidden = NO;
        [UIView animateWithDuration:0.8 animations:^{
            self.noAlbumslabel.alpha = 1.0;
        }];
    } else {
        NSIndexPath *topRowOfTableView = [NSIndexPath indexPathForRow:0 inSection:0];
        if (_selectedAlbumCollection.albums.count) {
            [self.tableView scrollToRowAtIndexPath:topRowOfTableView
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:YES];
        }
    }
}

- (void)setUpNoAlbumsLabelAppearance {
    self.noAlbumslabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    self.noAlbumslabel.text = @"No albums";
    self.noAlbumslabel.textColor = [UIColor whiteColor];
    self.noAlbumslabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.noAlbumslabel];
    self.noAlbumslabel.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    self.segmentedControl.hidden = NO;
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;
    
    [self setUpNoAlbumsLabelAppearance];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(yearChanged:)
                                                name:@"yearSelectedNotification"
                                              object:nil];
    if (!self.weeklySubmissions.albums.count) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)segmentedControlTapped:(UISegmentedControl *)sender {
    NSArray *allAlbumCollections = @[self.weeklySubmissions, self.photoWalks, self.miscellaneousAlbums];
    self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear
                                        fromAlbumCollection:allAlbumCollections[sender.selectedSegmentIndex]];
}

- (FTFAlbumCollection *)albumsForGivenYear:(NSString *)year fromAlbumCollection:(FTFAlbumCollection *)albumCollection {
    NSPredicate *yearPredicate = [NSPredicate predicateWithFormat:@"(yearCreated = %@)", year];
    NSArray *filteredAlbums = [albumCollection.albums filteredArrayUsingPredicate:yearPredicate];
    FTFAlbumCollection *filteredCollection = [[FTFAlbumCollection alloc] initWithAlbums:filteredAlbums andCollectionCategory:FTFAlbumCollectionCategoryCustom];
    return filteredCollection;
}

- (void)yearChanged:(NSNotification *)notification {
    [self.popover dismissPopoverAnimated:YES];
    self.selectedAlbumYear = [notification.userInfo objectForKey:@"year"];
    self.yearButton.title = self.selectedAlbumYear;
    NSArray *allAlbumCollections = @[self.weeklySubmissions, self.photoWalks, self.miscellaneousAlbums];
    self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear
                                        fromAlbumCollection:allAlbumCollections[self.segmentedControl.selectedSegmentIndex]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.selectedAlbumCollection.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FTFAlbumSelectionMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    FTFAlbum *album = self.selectedAlbumCollection.albums[indexPath.row];
//    if ([album.name hasPrefix:@"Week"]) {
//        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:album.name];
//        NSArray *words = [album.name componentsSeparatedByString:@": "];
//        NSString *week = [words firstObject];
//        NSRange range = [album.name rangeOfString:week];
//        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
//        [cell.albumName setAttributedText:attributedString];
//    } else {
//        cell.albumName.text = album.name;
//    }
    cell.albumName.text = album.name;
    [cell.albumThumbnail setImageWithURL:album.coverPhotoURL
                        placeholderImage:[UIImage imageNamed:@"placeholder"]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FTFAlbum *album = self.selectedAlbumCollection.albums[indexPath.row];
    NSDictionary *selectedAlbum = [NSDictionary dictionaryWithObjectsAndKeys:album, @"selectedAlbum", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"albumSelectedNotification"
                                                        object:self
                                                      userInfo:selectedAlbum];
    [self dismissButtonTapped:nil];
}

#pragma Year Popover

- (IBAction)yearButtonTapped:(UIBarButtonItem *)sender {
    self.yearPopoverTableViewController.years = [self allYearsFromAlbumCollection:self.weeklySubmissions];

    self.popover = [[WYPopoverController alloc] initWithContentViewController:self.yearPopoverTableViewController];
    self.popover.theme = [WYPopoverTheme themeForIOS7];
    CGSize size = self.popover.popoverContentSize;
    size.height = size.height / 3;
    size.width = size.width / 4.5;
    self.popover.popoverContentSize = size;
    [self.popover presentPopoverFromBarButtonItem:self.yearButton
                         permittedArrowDirections:WYPopoverArrowDirectionDown
                                         animated:YES
                                          options:WYPopoverAnimationOptionFadeWithScale];
}

- (NSArray *)allYearsFromAlbumCollection:(FTFAlbumCollection *)albumCollection {
    NSMutableArray *years = [NSMutableArray new];
    for (FTFAlbum *album in albumCollection.albums) {
        if (![years containsObject:album.yearCreated]) {
            [years addObject:album.yearCreated];
        }
    }
//    NSOrderedSet *yearsSet = [NSOrderedSet orderedSetWithArray:years];
//    [years removeAllObjects];
//    for (NSString *year in yearsSet) {
//        [years addObject:year];
//    }
    return years;
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//}

@end

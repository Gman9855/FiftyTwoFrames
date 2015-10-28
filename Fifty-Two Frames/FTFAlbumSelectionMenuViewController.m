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
#import "FTFAlbumCategoryCollection.h"

@interface FTFAlbumSelectionMenuViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) FTFYearPopoverTableViewController *yearPopoverTableViewController;
@property (nonatomic, strong) WYPopoverController *popover;
@property (nonatomic, strong) UILabel *noAlbumslabel;
@property (nonatomic, strong) NSArray *albumThumbnailPhotos;
@property (nonatomic, strong) FTFAlbumCollection *weeklySubmissions;
@property (nonatomic, strong) FTFAlbumCollection *photoWalks;
@property (nonatomic, strong) FTFAlbumCollection *miscellaneousAlbums;
@property (strong, nonatomic) FTFAlbumCollection *selectedAlbumCollection;
@property (nonatomic, strong) NSString *selectedAlbumYear;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *yearButton;
@property (nonatomic, strong) UIButton *refreshAlbumPhotosButton;

@end

static NSString * const reuseIdentifier = @"reuseIdentifier";

@implementation FTFAlbumSelectionMenuViewController

#pragma mark - View Setup

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

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAlbumCategoryCollection) name:@"RefreshAlbumCollection" object:nil];
}

- (void)fetchAlbumCategoryCollection {
    [[FiftyTwoFrames sharedInstance] requestAlbumCollectionWithCompletionBlock:^(FTFAlbumCategoryCollection *albumCollection, NSError *error) {
        if (!error) {
            if (albumCollection) {
                self.yearButton.enabled = YES;
                [self parseAlbumCollection:albumCollection];
            }
        } else {
            self.navigationController.toolbarHidden = NO;

            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                self.refreshAlbumPhotosButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.refreshAlbumPhotosButton addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [self.refreshAlbumPhotosButton setImage:[UIImage imageNamed:@"Refresh"] forState:UIControlStateNormal];
                [self.refreshAlbumPhotosButton sizeToFit];
                self.refreshAlbumPhotosButton.center = [self.navigationController.view convertPoint:self.navigationController.view.center fromView:self.navigationController.view.superview];
                [self.navigationController.view addSubview:self.refreshAlbumPhotosButton];
            });
        }
    }];
}

- (void)refreshButtonTapped:(UIButton *)sender {
    self.refreshAlbumPhotosButton.hidden = YES;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self fetchAlbumCategoryCollection];
}

- (void)parseAlbumCollection:(FTFAlbumCategoryCollection *)albumCategoryCollection {
    FTFAlbumCollection *weeklyThemeAlbums = [albumCategoryCollection albumCollectionForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    self.weeklySubmissions = weeklyThemeAlbums;
    self.photoWalks = [albumCategoryCollection albumCollectionForCategory:FTFAlbumCollectionCategoryPhotoWalks];
    self.miscellaneousAlbums = [albumCategoryCollection albumCollectionForCategory:FTFAlbumCollectionCategoryMiscellaneous];
    
    FTFAlbum *mostCurrentWeeklyAlbum = weeklyThemeAlbums.albums.firstObject;
    self.selectedAlbumCollection = [self albumsForGivenYear:mostCurrentWeeklyAlbum.yearCreated fromAlbumCollection:weeklyThemeAlbums];
    self.selectedAlbumYear = mostCurrentWeeklyAlbum.yearCreated;
    self.yearButton.title = mostCurrentWeeklyAlbum.yearCreated;
}

- (void)setSelectedAlbumCollection:(FTFAlbumCollection *)selectedAlbumCollection {
    _selectedAlbumCollection = selectedAlbumCollection;
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [UIView animateWithDuration:0.7 animations:^{
        self.navigationController.toolbarHidden = NO;
        self.segmentedControl.hidden = NO;
    }];
    
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

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    [self setUpNoAlbumsLabelAppearance];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(yearChanged:)
                                                name:@"yearSelectedNotification"
                                              object:nil];
    if (!self.weeklySubmissions.albums.count) {
        self.segmentedControl.hidden = YES;
        self.yearButton.enabled = NO;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading albums";
    }
}

#pragma mark - Action methods

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
    return years;
}

- (void)yearChanged:(NSNotification *)notification {
    [self.popover dismissPopoverAnimated:YES];
    self.selectedAlbumYear = [notification.userInfo objectForKey:@"year"];
    self.yearButton.title = self.selectedAlbumYear;
    NSArray *allAlbumCollections = @[self.weeklySubmissions, self.photoWalks, self.miscellaneousAlbums];
    self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear
                                        fromAlbumCollection:allAlbumCollections[self.segmentedControl.selectedSegmentIndex]];
}

@end

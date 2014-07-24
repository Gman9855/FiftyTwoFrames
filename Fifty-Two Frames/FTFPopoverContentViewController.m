//
//  FTFPopoverContentViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 7/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPopoverContentViewController.h"
#import "FTFPopoverYearTableViewController.h"
#import "WYPopoverController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "MBProgressHUD.h"


@interface FTFPopoverContentViewController () <WYPopoverControllerDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray *yearKeys;
@property (nonatomic, strong) NSArray *yearsMappingToAlbumInfo;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *selectedAlbumCollection;
@property (nonatomic, strong) UIPickerView *yearPicker;

@end

static NSString * const reuseIdentifier = @"reuseIdentifier";

@implementation FTFPopoverContentViewController

- (NSMutableArray *)yearKeys {
    if (!_yearKeys) {
        _yearKeys = [NSMutableArray new];
    }
    return _yearKeys;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.yearPicker.backgroundColor = [UIColor blueColor];
    [self.navigationController.view addSubview:self.yearPicker];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pic.jpg"]];
//    self.tableView.backgroundView = tempImageView;
    if (![self.weeklySubmissions count]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setWeeklySubmissions:(NSArray *)weeklySubmissions {
    _weeklySubmissions = [self mapYearsToAlbumDictionaries:weeklySubmissions];
    self.selectedAlbumCollection = _weeklySubmissions;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.tableView reloadData];
}

- (void)setPhotoWalks:(NSArray *)photoWalks {
    _photoWalks = [self mapYearsToAlbumDictionaries:photoWalks];
    [self.tableView reloadData];
}

- (void)setMiscellaneousAlbums:(NSArray *)miscellaneousAlbums {
    _miscellaneousAlbums = [self mapYearsToAlbumDictionaries:miscellaneousAlbums];
    [self.tableView reloadData];
}

- (NSArray *)mapYearsToAlbumDictionaries:(NSArray *)albumData {
    
    NSString *mostRecentYear = [[[albumData firstObject]valueForKeyPath:@"created_time"]substringToIndex:4];
    NSString *currentYearKey = mostRecentYear;
    NSMutableDictionary *albumYearsToAlbumInfo = [NSMutableDictionary new];
    NSMutableArray *albumsForYearInLoop = [NSMutableArray new];
    NSMutableArray *dictionariesOfYearsToAlbumInfo = [NSMutableArray new];
    for (NSDictionary *albumDict in albumData) {
        NSString *albumYear = [[albumDict valueForKeyPath:@"created_time"]substringToIndex:4];

        if (![currentYearKey isEqualToString:albumYear] || albumDict == [albumData lastObject]) {
            if (albumDict == [albumData lastObject]) {
                [albumsForYearInLoop addObject:albumDict];
            }
            [albumYearsToAlbumInfo setObject:[albumsForYearInLoop copy] forKey:currentYearKey];
            [dictionariesOfYearsToAlbumInfo addObject:[albumYearsToAlbumInfo copy]];
            [self.yearKeys addObject:currentYearKey];
            [albumsForYearInLoop removeAllObjects];
            [albumYearsToAlbumInfo removeAllObjects];
            [albumsForYearInLoop addObject:albumDict];
            currentYearKey = albumYear;
        } else {
            [albumsForYearInLoop addObject:albumDict];
        }
    }
    return [dictionariesOfYearsToAlbumInfo copy];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)segmentedControlTapped:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.selectedAlbumCollection = self.weeklySubmissions;
            [self.tableView reloadData];
            break;
        case 1:
            self.selectedAlbumCollection = self.photoWalks;
            [self.tableView reloadData];
            break;
        case 2:
            self.selectedAlbumCollection = self.miscellaneousAlbums;
            [self.tableView reloadData];
            break;
        default:
            break;
    }
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
    NSDictionary *latestYearAlbum = [self.selectedAlbumCollection firstObject];
    return [[latestYearAlbum valueForKeyPath:@"2014"] count];
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    CATransition *t = [CATransition animation];
//    t.duration = 0.60;
//    t.type = kCATransitionFade;
//    [cell.textLabel.layer addAnimation:t forKey:nil];
//    NSDictionary *albumName = self.albumNames[indexPath.row];
//    cell.textLabel.text = [albumName valueForKeyPath:@"name"];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSDictionary *albumCollection = [self.selectedAlbumCollection firstObject];
    NSArray *albums = [albumCollection valueForKey:@"2014"];
    NSDictionary *albumInfo = albums[indexPath.row];
    cell.textLabel.text = [albumInfo valueForKey:@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *albumYear = [self.selectedAlbumCollection firstObject];
    NSArray *albumCollection = [albumYear valueForKey:@"2014"];
    NSDictionary *album = albumCollection[indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"albumSelectedNotification"
                      object:self
                    userInfo:album];
}

#pragma Year Popover



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

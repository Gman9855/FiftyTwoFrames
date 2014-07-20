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
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (![self.albumNames count]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setAlbumNames:(NSArray *)albumNames {
    _albumNames = albumNames;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self mapYearSectionsToAlbumDictionaries];
    [self.tableView reloadData];
}

- (void)mapYearSectionsToAlbumDictionaries {
    
    NSString *mostRecentYear = [[[self.albumNames firstObject]valueForKeyPath:@"created_time"]substringToIndex:4];
    NSString *currentYearKey = mostRecentYear;
    NSMutableDictionary *albumYearsToAlbumInfo = [NSMutableDictionary new];
    NSMutableArray *albumsForYearInLoop = [NSMutableArray new];
    NSMutableArray *dictionariesOfYearsToAlbumInfo = [NSMutableArray new];
    for (NSDictionary *albumDict in self.albumNames) {
        NSString *albumYear = [[albumDict valueForKeyPath:@"created_time"]substringToIndex:4];

        if (![currentYearKey isEqualToString:albumYear] || albumDict == [self.albumNames lastObject]) {
            if (albumDict == [self.albumNames lastObject]) {
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
    self.yearsMappingToAlbumInfo = [dictionariesOfYearsToAlbumInfo copy];
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
    return [self.yearsMappingToAlbumInfo count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSDictionary *year = self.yearsMappingToAlbumInfo[section];
    NSArray *albumsFromYear = [year valueForKey:self.yearKeys[section]];
    return [albumsFromYear count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.yearKeys[section];
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
    NSDictionary *albumYear = self.yearsMappingToAlbumInfo[indexPath.section];
    NSArray *albumsFromYear = [albumYear valueForKey:self.yearKeys[indexPath.section]];
    NSDictionary *album = albumsFromYear[indexPath.row];
    cell.textLabel.text = [album valueForKeyPath:@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *albumYear = self.yearsMappingToAlbumInfo[indexPath.section];
    NSArray *albumsFromYear = [albumYear valueForKey:self.yearKeys[indexPath.section]];
    NSDictionary *album = albumsFromYear[indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"albumSelectedNotification"
                      object:self
                    userInfo:album];
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

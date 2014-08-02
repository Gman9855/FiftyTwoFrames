//
//  FTFPopoverContentViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 7/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPopoverContentViewController.h"
#import "WYPopoverController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "MBProgressHUD.h"
#import "FTFAlbum.h"
#import "FTFYearPopoverTableViewController.h"


@interface FTFPopoverContentViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) FTFYearPopoverTableViewController *yearPopoverTableViewController;
@property (nonatomic, strong) WYPopoverController *popover;
@property (nonatomic, strong) UILabel *noAlbumsForYearlabel;

@end

static NSString * const reuseIdentifier = @"reuseIdentifier";

@implementation FTFPopoverContentViewController

- (FTFYearPopoverTableViewController *)yearPopoverTableViewController {
    if (!_yearPopoverTableViewController) {
        _yearPopoverTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"yearPopoverVC"];
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

- (void)setSelectedAlbumCollection:(NSArray *)selectedAlbumCollection {
    _selectedAlbumCollection = selectedAlbumCollection;
    self.noAlbumsForYearlabel.hidden = YES;
    if (![_selectedAlbumCollection count]) {
        self.noAlbumsForYearlabel.alpha = 0.0;
        self.noAlbumsForYearlabel.hidden = NO;
        [UIView animateWithDuration:0.8 animations:^{
            self.noAlbumsForYearlabel.alpha = 1.0;


        }];
    }
}

- (void)setUpNoAlbumsForYearLabel {
    self.noAlbumsForYearlabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 320, 21)];
    self.noAlbumsForYearlabel.text = @"No albums";
    self.noAlbumsForYearlabel.textColor = [UIColor whiteColor];
    self.noAlbumsForYearlabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView addSubview:self.noAlbumsForYearlabel];
    self.noAlbumsForYearlabel.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpNoAlbumsForYearLabel];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pic.jpg"]];
//    self.tableView.backgroundView = tempImageView;
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(yearChanged:)
                                                name:@"yearSelectedNotification"
                                              object:nil];
    if (![self.weeklySubmissions count]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
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
            self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.weeklySubmissions];
            [self.tableView reloadData];
            break;
        case 1:
            self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.photoWalks];
            [self.tableView reloadData];
            break;
        case 2:
            self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.miscellaneousAlbums];
            [self.tableView reloadData];
            break;
        default:
            break;
    }
}

- (NSArray *)albumsForGivenYear:(NSString *)year fromAlbumCollection:(NSArray *)albumCollection {
    NSPredicate *yearPredicate = [NSPredicate predicateWithFormat:@"(yearCreated = %@)", year];
    return [albumCollection filteredArrayUsingPredicate:yearPredicate];
}

- (void)yearChanged:(NSNotification *)notification {
    [self.popover dismissPopoverAnimated:YES];
    self.selectedAlbumYear = [notification.userInfo objectForKey:@"year"];
    self.yearButton.title = self.selectedAlbumYear;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.weeklySubmissions];
    } else if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.photoWalks];
    } else {
        self.selectedAlbumCollection = [self albumsForGivenYear:self.selectedAlbumYear fromAlbumCollection:self.miscellaneousAlbums];
    }
    
    [self.tableView reloadData];
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
    return [self.selectedAlbumCollection count];
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
    FTFAlbum *album = self.selectedAlbumCollection[indexPath.row];
    cell.textLabel.text = album.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FTFAlbum *album = self.selectedAlbumCollection[indexPath.row];
    NSDictionary *selectedAlbum = [NSDictionary dictionaryWithObjectsAndKeys:album, @"selectedAlbum", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"albumSelectedNotification"
                      object:self
                    userInfo:selectedAlbum];
}

#pragma Year Popover

- (IBAction)yearButtonTapped:(UIBarButtonItem *)sender {
    self.yearPopoverTableViewController.years = [self allYearsFromAlbumCollection:self.weeklySubmissions];

    self.popover = [[WYPopoverController alloc] initWithContentViewController:self.yearPopoverTableViewController];
    [self.popover presentPopoverFromBarButtonItem:self.yearButton
                    permittedArrowDirections:WYPopoverArrowDirectionAny
                                    animated:YES
                                     options:WYPopoverAnimationOptionFadeWithScale];
    CGSize size = self.popover.popoverContentSize;
    size.height = size.height / 3;
    size.width = size.width / 4;
    self.popover.popoverContentSize = size;
}

- (NSArray *)allYearsFromAlbumCollection:(NSArray *)albumCollection {
    NSMutableArray *years = [NSMutableArray new];
    for (FTFAlbum *album in albumCollection) {
        [years addObject:album.yearCreated];
    }
    NSOrderedSet *yearsSet = [NSOrderedSet orderedSetWithArray:years];
    [years removeAllObjects];
    for (NSString *year in yearsSet) {
        [years addObject:year];
    }
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

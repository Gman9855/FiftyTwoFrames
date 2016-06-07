//
//  FTFSideMenuViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 6/5/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFSideMenuViewController.h"
#import "FTFPhotoCollectionGridViewController.h"
#import "FiftyTwoFrames.h"
#import "FTFUser.h"
#import "UIImageView+WebCache.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
@import SafariServices;
#include "REFrostedViewController.h"

@interface FTFSideMenuViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (weak, nonatomic) IBOutlet UILabel *name;


@end

@implementation FTFSideMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor colorWithRed:150/255.0f green:161/255.0f blue:177/255.0f alpha:1.0f];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.opaque = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 214.0f)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 40, 100, 100)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        FiftyTwoFrames *ftf = [FiftyTwoFrames sharedInstance];
        
        [imageView setImageWithURL:ftf.user.profilePictureURL];
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 50.0;
        imageView.layer.borderColor = [UIColor orangeColor].CGColor;
        imageView.layer.borderWidth = 3.0f;
        imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        imageView.layer.shouldRasterize = YES;
        imageView.clipsToBounds = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 155, self.frostedViewController.menuViewSize.width - 18, 50)];
        label.text = ftf.user.name;
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 2;
        label.font = [UIFont fontWithName:@"Lato-Regular" size:19];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        
        [view addSubview:imageView];
        [view addSubview:label];
        view;
    });
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
//    cell.textLabel.textColor = [UIColor colorWithRed:62/255.0f green:68/255.0f blue:75/255.0f alpha:1.0f];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Lato-Regular" size:17];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *urlString;
    switch (indexPath.row) {
        case 0:
            urlString = @"http://52frames.com/deadline/";
            break;
        case 1:
            urlString = @"http://www.52Frames.com/about/";
            break;
        case 2:
            urlString = @"http://52frames.com/get-started/";
            break;
        case 3:
            urlString = @"http://www.patreon.com/52Frames";
            break;
        case 4:
            [[FBSDKLoginManager new] logOut];
            break;
        default:
            break;
    }
    
    if (indexPath.row != 4) {
        FTFPhotoCollectionGridViewController *grid = (FTFPhotoCollectionGridViewController *)self.frostedViewController.contentViewController;
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString] entersReaderIfAvailable:NO];
        [grid presentViewController:safariVC animated:YES completion:nil];
    }
    
    
    [self.frostedViewController hideMenuViewController];

}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.section == 0) {
        NSArray *titles = @[@"This week's challenge", @"About 52Frames", @"Join the community", @"Become a Patron", @"Log out"];
        cell.textLabel.text = titles[indexPath.row];
    }
    
    return cell;
}

@end

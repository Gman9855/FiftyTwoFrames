//
//  FTFPopoverContentViewController.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 7/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FTFAlbumSelectionMenuViewControllerDelegate <NSObject>

- (void)albumSelectionMenuViewControllerdidTapDismissButton;

@end

@interface FTFAlbumSelectionMenuViewController : UITableViewController

@property (nonatomic, weak) id <FTFAlbumSelectionMenuViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray *weeklySubmissions;
@property (nonatomic, strong) NSArray *photoWalks;
@property (nonatomic, strong) NSArray *miscellaneousAlbums;
@property (strong, nonatomic) NSArray *selectedAlbumCollection;
@property (nonatomic, strong) NSString *selectedAlbumYear;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *yearButton;

- (NSArray *)albumsForGivenYear:(NSString *)year fromAlbumCollection:(NSArray *)albumCollection;


@end

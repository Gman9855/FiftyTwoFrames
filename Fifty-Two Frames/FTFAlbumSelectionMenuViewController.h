//
//  FTFPopoverContentViewController.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 7/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FTFAlbumCollection;

@interface FTFAlbumSelectionMenuViewController : UITableViewController

@property (nonatomic, strong) FTFAlbumCollection *weeklySubmissions;
@property (nonatomic, strong) FTFAlbumCollection *photoWalks;
@property (nonatomic, strong) FTFAlbumCollection *miscellaneousAlbums;
@property (strong, nonatomic) FTFAlbumCollection *selectedAlbumCollection;
@property (nonatomic, strong) NSString *selectedAlbumYear;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *yearButton;

- (FTFAlbumCollection *)albumsForGivenYear:(NSString *)year fromAlbumCollection:(FTFAlbumCollection *)albumCollection;


@end

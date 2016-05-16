//
//  FTFFiltersViewController.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/13/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    FTFSortOrderName,
    FTFSortOrderLikes,
    FTFSortOrderComments,
    FTFSortOrderNone
} FTFSortOrder;

@protocol FTFFiltersViewControllerDelegate <NSObject>

- (void)filtersViewControllerDidSaveFilters:(NSString *)searchTerm nameOnly:(BOOL)nameOnly sortOrder:(FTFSortOrder)sortOrder;
- (void)filtersViewControllerDidResetFilters;

@end

@interface FTFFiltersViewController : UITableViewController

@property (nonatomic, weak) id <FTFFiltersViewControllerDelegate> delegate;

@end

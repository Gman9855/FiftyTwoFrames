//
//  FTFAlbumCollection.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FTFAlbumCollectionCategoryWeeklyThemes,
    FTFAlbumCollectionCategoryPhotoWalks,
    FTFAlbumCollectionCategoryMiscellaneous,
    FTFAlbumCollectionCategoryAll
} FTFAlbumCollectionCategory;

@interface FTFAlbumCollection : NSObject

- (instancetype)initWithAlbums:(NSArray *)albums;  // initializes with FTFAlbum's

- (NSArray *)albumsForCategory:(FTFAlbumCollectionCategory)collectionCategory;

@property (nonatomic, readonly, strong) NSArray *albums;

@end

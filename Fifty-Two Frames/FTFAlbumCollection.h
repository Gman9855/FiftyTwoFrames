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

//- (instancetype)initWithDictionary:(NSDictionary *)facebookResultData;  // initializes with FTFAlbum's

- (NSArray *)albumsForCategory:(FTFAlbumCollectionCategory)collectionCategory;
- (NSArray *)retrieveAllPhotoAlbums;

@end

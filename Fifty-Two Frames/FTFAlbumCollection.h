//
//  FTFAlbumCollection.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FTFAlbum;

typedef enum {
    FTFAlbumCollectionCategoryWeeklyThemes,
    FTFAlbumCollectionCategoryPhotoWalks,
    FTFAlbumCollectionCategoryMiscellaneous,
    FTFAlbumCollectionCategoryCustom
} FTFAlbumCollectionCategory;

@interface FTFAlbumCollection : NSObject

- (instancetype)initWithAlbums:(NSArray *)albums andCollectionCategory:(FTFAlbumCollectionCategory)collectionCategory;  // initializes with FTFAlbum's

@property (nonatomic, readonly) FTFAlbumCollectionCategory collectionCategory;
@property (nonatomic, readonly, strong) NSArray<FTFAlbum *> *albums;

@end

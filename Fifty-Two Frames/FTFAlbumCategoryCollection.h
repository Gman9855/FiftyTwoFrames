//
//  FTFAlbumCategoryCollection.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/10/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTFAlbumCollection.h"

@interface FTFAlbumCategoryCollection : NSObject

@property (nonatomic, readonly, strong) NSArray *albumCollections;

- (instancetype)initWithAlbumCollections:(NSArray *)albumCollections;

- (FTFAlbumCollection *)albumCollectionForCategory:(FTFAlbumCollectionCategory)collectionCategory;


@end

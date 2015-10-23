//
//  FTFAlbumCategoryCollection.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/10/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbumCategoryCollection.h"

@implementation FTFAlbumCategoryCollection

- (instancetype)initWithAlbumCollections:(NSArray *)albumCollections {
    if (self = [super init]) {
        _albumCollections = albumCollections;
    }
    return self;
}

- (FTFAlbumCollection *)albumCollectionForCategory:(FTFAlbumCollectionCategory)collectionCategory {
    FTFAlbumCollection *collection;
    for (FTFAlbumCollection *albumCollection in _albumCollections) {
        if (albumCollection.collectionCategory == collectionCategory) {
            collection = albumCollection;
        }
    }
    return collection;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {
        // Decode the property values by key, and assign them to the correct ivars
        _albumCollections = [coder decodeObjectForKey:@"albumCollections"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    // Encode our ivars using string keys
    [coder encodeObject:_albumCollections forKey:@"albumCollections"];
}

@end

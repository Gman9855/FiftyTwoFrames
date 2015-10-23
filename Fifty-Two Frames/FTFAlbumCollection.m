//
//  FTFAlbumCollection.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FTFAlbumCollection ()

@property (nonatomic, readwrite, strong) NSArray *albums;
@property (nonatomic, readwrite) FTFAlbumCollectionCategory collectionCategory;

@end

@implementation FTFAlbumCollection

- (instancetype)initWithAlbums:(NSArray *)albums andCollectionCategory:(FTFAlbumCollectionCategory)collectionCategory{
    if (self = [super init]) {
        _albums = albums;
        _collectionCategory = collectionCategory;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {
        // Decode the property values by key, and assign them to the correct ivars
        _albums = [coder decodeObjectForKey:@"albums"];
        NSNumber *collectionCategory = [coder decodeObjectForKey:@"collectionCategory"];
        _collectionCategory = [collectionCategory intValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    // Encode our ivars using string keys
    [coder encodeObject:_albums forKey:@"albums"];
    NSNumber *collectionCategory = [NSNumber numberWithInt:_collectionCategory];
    [coder encodeObject:collectionCategory forKey:@"collectionCategory"];
}

@end

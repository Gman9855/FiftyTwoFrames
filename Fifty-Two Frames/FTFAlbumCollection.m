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

@end

@implementation FTFAlbumCollection

- (instancetype)initWithAlbums:(NSArray *)albums andCollectionCategory:(FTFAlbumCollectionCategory)collectionCategory{
    if (self = [super init]) {
        _albums = albums;
        _collectionCategory = collectionCategory;
    }
    return self;
}

@end

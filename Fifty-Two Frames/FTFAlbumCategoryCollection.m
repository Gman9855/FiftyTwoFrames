//
//  FTFAlbumCategoryCollection.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/10/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbumCategoryCollection.h"
#import "FTFAlbum.h"

@implementation FTFAlbumCategoryCollection

- (instancetype)initWithAlbumCollections:(NSArray *)albumCollections {
    if (self = [super init]) {
        _albumCollections = albumCollections;
    }
    return self;
}

- (instancetype)initWithArray:(NSArray *)array {
    if (self = [super init]) {
        _albumCollections = [self albumCategoryCollectionsFromResponseArray:array];
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

- (NSArray *)albumCategoryCollectionsFromResponseArray:(NSArray *)array {
    NSMutableArray *weeklyThemeAlbums = [NSMutableArray new];
    NSMutableArray *photoWalkAlbums = [NSMutableArray new];
    NSMutableArray *miscellaneousAlbums = [NSMutableArray new];
    
    for (NSDictionary *dict in array) {
        
        NSArray *albumInfoDicts = [dict valueForKeyPath:@"albums.data"];
        if (!albumInfoDicts) {
            albumInfoDicts = [dict valueForKeyPath:@"data"];
        }
        NSPredicate *weekPredicate = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@)", @"week"];
        NSPredicate *photoWalkPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@ || name CONTAINS[cd] %@ || name CONTAINS[cd] %@)", @"photowalk", @"photo walk", @"photo-walk"];
        NSPredicate *orPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[weekPredicate, photoWalkPredicate]];
        NSPredicate *compoundPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:orPredicate];
        
        NSSortDescriptor *createdDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:NO];
        NSArray *weeklyThemeDicts = [[albumInfoDicts filteredArrayUsingPredicate:weekPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
        NSArray *photoWalkDicts = [[albumInfoDicts filteredArrayUsingPredicate:photoWalkPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
        NSArray *miscellaneousAlbumDicts = [[albumInfoDicts filteredArrayUsingPredicate:compoundPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
        
        NSArray *weekArrays = @[weeklyThemeDicts, weeklyThemeAlbums];
        NSArray *photoWalkArrays = @[photoWalkDicts, photoWalkAlbums];
        NSArray *miscArrays = @[miscellaneousAlbumDicts, miscellaneousAlbums];
        NSArray *arrayOfAlbumCollectionArrays = @[weekArrays, photoWalkArrays, miscArrays];
        
        for (NSArray *array in arrayOfAlbumCollectionArrays) {
            NSArray *source = array[0];
            NSMutableArray *destination = array[1];
            
            for (NSDictionary *dict in source) {
                FTFAlbum *album = [FTFAlbum new];
                album.name = [dict valueForKey:@"name"];
                album.albumID = [dict valueForKey:@"id"];
                album.info = [dict valueForKey:@"description"];
                NSArray *pictureURLstring = [dict valueForKeyPath:@"photos.data.picture"];
                album.coverPhotoURL = [NSURL URLWithString:[pictureURLstring firstObject]];
                album.yearCreated = [[dict valueForKeyPath:@"created_time"]substringToIndex:4];
                if (album.coverPhotoURL) {
                    [destination addObject:album];
                }
            }
        }
    }
    
    FTFAlbumCollection *weeklyThemeCollection = [[FTFAlbumCollection alloc] initWithAlbums:weeklyThemeAlbums andCollectionCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    FTFAlbumCollection *photoWalkCollection = [[FTFAlbumCollection alloc] initWithAlbums:photoWalkAlbums andCollectionCategory:FTFAlbumCollectionCategoryPhotoWalks];
    FTFAlbumCollection *miscellaneousCollection = [[FTFAlbumCollection alloc] initWithAlbums:miscellaneousAlbums andCollectionCategory:FTFAlbumCollectionCategoryMiscellaneous];
    
    return @[weeklyThemeCollection, photoWalkCollection, miscellaneousCollection];
}

//- (id)initWithCoder:(NSCoder *)coder
//{
//    if ((self = [super init]))
//    {
//        // Decode the property values by key, and assign them to the correct ivars
//        _albumCollections = [coder decodeObjectForKey:@"albumCollections"];
//    }
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)coder
//{
//    // Encode our ivars using string keys
//    [coder encodeObject:_albumCollections forKey:@"albumCollections"];
//}

@end

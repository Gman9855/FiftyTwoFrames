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

@property (nonatomic, strong) NSArray *allPhotoAlbums;
@property (nonatomic, strong) NSArray *weeklyThemeAlbums;
@property (nonatomic, strong) NSArray *photoWalkAlbums;
@property (nonatomic, strong) NSArray *miscellaneousAlbums;

@end

@implementation FTFAlbumCollection

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(populateAlbumCategoryArrays:)
                                                     name:@"albumDataReceivedFromFacebookNotification"
                                                   object:nil];
    }
    return self;
}

- (NSArray *)allPhotoAlbums {
    if (!_allPhotoAlbums) {
        _allPhotoAlbums = @[self.weeklyThemeAlbums, self.photoWalkAlbums, self.miscellaneousAlbums];
    }
    return _allPhotoAlbums;
}

- (NSArray *)albumsForCategory:(FTFAlbumCollectionCategory)collectionCategory {
    if (collectionCategory == FTFAlbumCollectionCategoryAll) {
        return self.allPhotoAlbums;
    } else {
        return self.allPhotoAlbums[collectionCategory];
    }
}

- (NSArray *)retrieveAllPhotoAlbums {
    return self.allPhotoAlbums;
}

//- (void)makeRequestForAlbumData;
//{
//    [FBRequestConnection startWithGraphPath:@"/180889155269546?fields=albums.limit(10000).fields(name)"
//                                 parameters:nil
//                                 HTTPMethod:@"GET"
//                          completionHandler:^(
//                                              FBRequestConnection *connection,
//                                              id result,
//                                              NSError *error
//                                              ) {
//                              /* handle the result */
//                              [self populateAlbumCategoryArrays:result];
//                          }];
//}

- (void)populateAlbumCategoryArrays:(NSNotification *)notification;
{
    NSDictionary *fr = notification.userInfo;
    NSArray *albumInfoDicts = [fr valueForKeyPath:@"albums.data"];
    NSPredicate *weekPredicate = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@)", @"week"];
    NSPredicate *photoWalkPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@ || name CONTAINS[cd] %@ || name CONTAINS[cd] %@)", @"photowalk", @"photo walk", @"photo-walk"];
    NSPredicate *orPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[weekPredicate, photoWalkPredicate]];
    NSPredicate *compoundPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:orPredicate];

    NSSortDescriptor *createdDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:NO];
    NSArray *weeklyThemeDicts = [[albumInfoDicts filteredArrayUsingPredicate:weekPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    NSArray *photoWalkDicts = [[albumInfoDicts filteredArrayUsingPredicate:photoWalkPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    NSArray *miscellaneousAlbumDicts = [[albumInfoDicts filteredArrayUsingPredicate:compoundPredicate]sortedArrayUsingDescriptors:@[createdDateSortDescriptor]];
    
    NSMutableArray *weeklyThemeAlbums = [NSMutableArray new];
    NSMutableArray *photoWalkAlbums = [NSMutableArray new];
    NSMutableArray *miscellaneousAlbums = [NSMutableArray new];
    
    NSArray *weekArrays = @[weeklyThemeDicts, weeklyThemeAlbums];
    NSArray *photoWalkArrays = @[photoWalkDicts, photoWalkAlbums];
    NSArray *miscArrays = @[miscellaneousAlbumDicts, miscellaneousAlbums];
    NSArray *arrayOfAlbumCollectionArrays = @[weekArrays, photoWalkArrays, miscArrays];
    
    for (NSArray *array in arrayOfAlbumCollectionArrays) {
        NSArray *source = [array firstObject];
        NSMutableArray *destination = array[1];
        
        for (NSDictionary *dict in source) {
            FTFAlbum *album = [FTFAlbum new];
            album.name = [dict valueForKey:@"name"];
            album.albumID = [dict valueForKey:@"id"];
            album.yearCreated = [[dict valueForKey:@"created_time"]substringToIndex:4];
            [destination addObject:album];
        }
    }
    
    self.weeklyThemeAlbums = weeklyThemeAlbums;
    self.photoWalkAlbums = photoWalkAlbums;
    self.miscellaneousAlbums = miscellaneousAlbums;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishLoadingAlbumCollectionNotification"
                                                        object:self];
}

@end

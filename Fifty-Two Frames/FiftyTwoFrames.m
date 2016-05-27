//
//  FTFFacebook.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FiftyTwoFrames.h"

#import "FTFAlbumCategoryCollection.h"
#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import "FTFPhotoComment.h"
#import "FTFUser.h"
#import "FTFFiltersViewController.h"
#import "TTTTimeIntervalFormatter.h"
#import "SDWebImageManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

static NSString * const facebookPageID = @"180889155269546";

@interface FiftyTwoFrames ()

@property (nonatomic, strong) FBSDKGraphRequestConnection *requestConnection;

@property (nonatomic, strong) NSString *nextPageOfAlbumsURL;
@property (nonatomic, strong) NSString *nextPageOfAlbumPhotoResultsURL;

@property (nonatomic, strong) NSDictionary *photoRequestParameters;

@property (nonatomic, strong) NSString *graphPathForNameSearch;
@property (nonatomic, strong) NSDictionary *parametersForNameSearch;

@property (nonatomic, strong) NSMutableArray *allNameAndIdResponsesForAlbum;
@property (nonatomic, strong) NSMutableDictionary *albumIdsToNameAndIdsArrays;
@property (nonatomic, strong) NSMutableDictionary *albumResultsFromFacebook;
@property (nonatomic, strong) NSMutableArray *albumDicts;
@property (nonatomic, strong) NSMutableArray *albumPhotoDicts;
@property (nonatomic, strong) NSArray *filteredNamesAndIds;
@property (nonatomic, strong) NSString *idForCurrentAlbum;

@property (nonatomic, strong) NSMutableArray *weeklyThemeAlbums;
@property (nonatomic, strong) NSMutableArray *photoWalkAlbums;
@property (nonatomic, strong) NSMutableArray *miscellaneousAlbums;

@property (nonatomic, strong, readwrite) FTFUser *user;

@property (nonatomic, assign) FTFSortOrder sortOrder;

@end

NSInteger _pagingIndexForFilteredResults = 0;
BOOL _shouldProvideFilteredResults = NO;

@implementation FiftyTwoFrames

+ (instancetype)sharedInstance {
    static FiftyTwoFrames *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (NSDictionary *)photoRequestParameters {
    if (!_photoRequestParameters) {
        _photoRequestParameters = @{@"fields" : @"images,id,name,likes.limit(0).summary(true).fields(has_liked),comments.fields(from.fields(picture.type(large),id,name),created_time,message)"};
    }
    
    return _photoRequestParameters;
}

- (NSDictionary *)parametersForNameSearch {
    if (!_parametersForNameSearch) {
        _parametersForNameSearch = [NSDictionary dictionaryWithObjectsAndKeys:@"name, likes.limit(0).summary(true), comments.limit(0).summary(true)", @"fields", nil];
    }
    
    return _parametersForNameSearch;
}

- (FTFUser *)user {
    if (!_user) {
        __block BOOL done = NO;
        [self requestUserWithCompletionBlock:^(FTFUser *user, NSError *error) {
            _user = user;
            done = YES;
        }];
    
        while (!done) [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    return _user;
}

- (NSMutableArray *)allNameAndIdResponsesForAlbum {
    if (!_allNameAndIdResponsesForAlbum) {
        _allNameAndIdResponsesForAlbum = [NSMutableArray new];
    }
    
    return _allNameAndIdResponsesForAlbum;
}

- (NSMutableDictionary *)albumIdsToNameAndIdsArrays {
    if (!_albumIdsToNameAndIdsArrays) {
        _albumIdsToNameAndIdsArrays = [NSMutableDictionary new];
    }
    
    return _albumIdsToNameAndIdsArrays;
}

#pragma mark - Public Methods

- (void)requestUserWithCompletionBlock:(void (^)(FTFUser *user, NSError *error))block {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"id, name, picture.fields(url)", @"fields", nil];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            self.user = [[FTFUser alloc] initWithDictionary:result];
        }
        if (block) {
            if (!error) {
                block(self.user, nil);
            } else {
                block(nil, error);
            }
        }
    }];
}

- (void)requestLatestWeeklyThemeAlbumWithCompletionBlock:(void (^)(FTFAlbum *album, NSError *error, BOOL finishedPaging))block {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"albums.limit(10).fields(name,description,created_time,photos.limit(1).fields(picture))", @"fields", nil];
    NSString *graphPath = [NSString stringWithFormat:@"/%@", facebookPageID];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            block(nil, error, YES);
        } else {
            FTFAlbumCategoryCollection *categoryCollection = [[FTFAlbumCategoryCollection alloc] initWithArray:@[result]];
            FTFAlbumCollection *weeklyThemes = [categoryCollection albumCollectionForCategory:FTFAlbumCollectionCategoryWeeklyThemes];
            __block FTFAlbum *latestAlbum = weeklyThemes.albums.firstObject;
            [self requestAlbumPhotosForAlbumWithAlbumID:latestAlbum.albumID completionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                if (!error) {
                    latestAlbum.photos = photos;
                    block(latestAlbum, nil, finishedPaging);
                } else {
                    block(nil, error, YES);
                }
            }];
        }
    }];
    
    [self requestUserWithCompletionBlock:nil];
}

- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCategoryCollection *, NSError *))block;
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"albums.limit(50).fields(name,description,created_time,photos.limit(1).fields(picture))", @"fields", nil];
    
    NSString *graphPath = [NSString stringWithFormat:@"/%@?albums.limit(50)", facebookPageID];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (block) {
            if (!error) {
                self.albumDicts = [NSMutableArray new];
                [self.albumDicts addObject:result];
                NSString *nextPage = [result valueForKeyPath:@"albums.paging.next"];
                self.nextPageOfAlbumsURL = [nextPage substringFromIndex:31];
                [self requestRemainingAlbumsWithCompletionBlock:^(FTFAlbumCategoryCollection *albumCategoryCollection, NSError *error) {
                    if (error) {
                        block(nil, error);
                    } else {
                        block(albumCategoryCollection, error);
                    }
                }];
            } else {
                block(nil, error);
            }
        } else {
            return;
        }
    }];
}

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID completionBlock:(void (^)(NSArray *photos, NSError *error, BOOL finishedPaging))block
{
    self.idForCurrentAlbum = albumID;
    _shouldProvideFilteredResults = NO;
    if (self.requestConnection) {
        [self.requestConnection cancel];
        self.requestConnection = nil;
    }
    
    NSString *graphPath = [NSString stringWithFormat:@"/%@/photos?limit=50", albumID];
    self.graphPathForNameSearch = [NSString stringWithFormat:@"/%@/photos?limit=100", albumID];
    
    self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:self.photoRequestParameters];
    __weak typeof(self) weakSelf = self;
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (block) {
            if (!error) {
                NSArray *albumPhotos = [FTFImage photosWithPhotoResponse:[result valueForKey:@"data"]];
                NSString *nextPage = [result valueForKeyPath:@"paging.next"];
                if (nextPage == NULL) {
                    block(albumPhotos, nil, YES);
                } else {
                    weakSelf.nextPageOfAlbumPhotoResultsURL = [nextPage substringFromIndex:31];
                    block(albumPhotos, nil, NO);
                }
            } else {
                block(nil, error, YES);
            }
        } else {
            return;
        }
    }];
    
    [self.requestConnection start];
}

- (void)requestRemainingAlbumsWithCompletionBlock:(void (^)(FTFAlbumCategoryCollection *albumCategoryCollection, NSError *error))block {
    [[[FBSDKGraphRequest alloc] initWithGraphPath:self.nextPageOfAlbumsURL parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            NSString *nextPage = [result valueForKeyPath:@"paging.next"];
            self.nextPageOfAlbumsURL = [nextPage substringFromIndex:31];
            [self.albumDicts addObject:result];
            if (self.nextPageOfAlbumsURL.length > 0) {
                [self requestRemainingAlbumsWithCompletionBlock:block];
            } else {
                FTFAlbumCategoryCollection *albumCategoryCollection = [[FTFAlbumCategoryCollection alloc] initWithArray:self.albumDicts];
                block(albumCategoryCollection, nil);
            }
        }
    }];
}

- (void)requestNextPageOfAlbumPhotosFromFilteredResults:(BOOL)filtered withCompletionBlock:(void (^)(NSArray *photos, NSError *error, BOOL finishedPaging))block {
    if (self.requestConnection) {
        [self.requestConnection cancel];
        self.requestConnection = nil;
    }
    NSString *graphPath = filtered ? [self graphPathFromFilteredNamesAndIds:self.filteredNamesAndIds[_pagingIndexForFilteredResults]] : self.nextPageOfAlbumPhotoResultsURL;
    NSDictionary *parameters = filtered ? self.photoRequestParameters : nil;
    BOOL finishedPagingFilteredResults = _pagingIndexForFilteredResults == self.filteredNamesAndIds.count - 1;
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:parameters];
    self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (filtered) {
            NSMutableArray *albumPhotos = [NSMutableArray new];
            NSArray *dataForNextBatchOfPhotos = weakSelf.filteredNamesAndIds[_pagingIndexForFilteredResults];
            for (FTFImage *photo in dataForNextBatchOfPhotos) {
                NSString *photoId = photo.photoID;
                NSArray *parsedPhoto = [FTFImage photosWithPhotoResponse:[result valueForKey:photoId]];
                if (parsedPhoto.count > 0) {
                    [albumPhotos addObject:(FTFImage *)parsedPhoto.firstObject];
                }
            }
            
            if (self.sortOrder != FTFSortOrderNone) {
                NSArray *sortedPhotos = [weakSelf sortedArray:albumPhotos withSortOrder:weakSelf.sortOrder];
                block(sortedPhotos, nil, finishedPagingFilteredResults);
            } else {
                block(albumPhotos, nil, finishedPagingFilteredResults);
            }

            _pagingIndexForFilteredResults++;
        } else {
            NSString *nextPage = [result valueForKeyPath:@"paging.next"];
            NSArray *nextBatchOfAlbumPhotos = [FTFImage photosWithPhotoResponse:[result valueForKey:@"data"]];

            if (nextPage == NULL) {
                block(nextBatchOfAlbumPhotos, nil, YES);
            } else {
                weakSelf.nextPageOfAlbumPhotoResultsURL = [nextPage substringFromIndex:31];
                block(nextBatchOfAlbumPhotos, nil, NO);
            }
        }
    }];
    
    [self.requestConnection start];
}

- (void)requestAlbumPhotosWithFilters:(NSDictionary *)filters albumId:(NSString *)albumId completionBlock:(void (^)(NSArray *photos, NSError *error, BOOL finishedPaging))block {
    _shouldProvideFilteredResults = YES;
    _pagingIndexForFilteredResults = 0;
    self.sortOrder = FTFSortOrderNone;

    [self namesAndIdsForFilters:filters albumId:albumId completionBlock:^(NSArray *namesAndIds, NSError *error) {
        if (error) {
            block(nil, error, YES);
            return;
        }
        NSString *graphPath = [self graphPathFromFilteredNamesAndIds:namesAndIds];

        [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:self.photoRequestParameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (block) {
                if (!error) {
                    NSMutableArray *albumPhotos = [NSMutableArray new];
                    for (FTFImage *photo in namesAndIds) {
                        NSString *photoId = photo.photoID;
                        NSArray *parsedPhoto = [FTFImage photosWithPhotoResponse:[result valueForKey:photoId]];

                        if (parsedPhoto.count > 0) {
                            [albumPhotos addObject:(FTFImage *)parsedPhoto.firstObject];
                        }
                    }
                    BOOL finishedPaging = _pagingIndexForFilteredResults == self.filteredNamesAndIds.count - 1;
                    if (!finishedPaging) {
                        _pagingIndexForFilteredResults++;
                    }
                    if (![filters[@"sortOrder"] isEqual:[NSNumber numberWithInt:3]]) {
                        FTFSortOrder sortOrder = (FTFSortOrder)[filters[@"sortOrder"] integerValue];
                        NSArray *sortedPhotos = [self sortedArray:albumPhotos withSortOrder:sortOrder];
                        block(sortedPhotos, nil, finishedPaging);
                    } else {
                        block(albumPhotos, nil, finishedPaging);
                    }
                } else {
                    block(nil, error, YES);
                }
            } else {
                return;
            }
        }];
    }];
}

- (void)requestNextPageOfFilteredResultsWithCompletionBlock:(void (^)(NSArray *photos, NSError *error))block {
    NSArray *nextBatchOfFilteredPhotos = self.filteredNamesAndIds[_pagingIndexForFilteredResults];
    NSString *graphPath = [self graphPathFromFilteredNamesAndIds:nextBatchOfFilteredPhotos];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:self.photoRequestParameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (block) {
            if (!error) {
                NSMutableArray *albumPhotos = [NSMutableArray new];
                for (FTFImage *photo in nextBatchOfFilteredPhotos) {
                    NSString *photoId = photo.photoID;
                    NSArray *parsedPhoto = [FTFImage photosWithPhotoResponse:[result valueForKey:photoId]];
                    if (parsedPhoto.count > 0) {
                        [albumPhotos addObject:(FTFImage *)parsedPhoto.firstObject];
                    }
                }
                
                if (_pagingIndexForFilteredResults != self.filteredNamesAndIds.count - 1) {
                    _pagingIndexForFilteredResults++;
                }
                block(albumPhotos, nil);
                
            } else {
                block(nil, error);
            }
        } else {
            return;
        }
    }];
}

- (void)publishPhotoCommentWithPhotoID:(NSString *)photoID comment:(NSString *)comment completionBlock:(void (^)(NSError *error))block
{
    NSDictionary *params = @{@"message" : comment};
    [[[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/comments", photoID] parameters:params HTTPMethod:@"Post"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        block(error);
    }];
}

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID
                    completionBlock:(void (^)(NSError *))block
{
    if (self.requestConnection) {
        [self.requestConnection cancel];
        self.requestConnection = nil;
    }
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoID] parameters:nil HTTPMethod:@"POST"];
    self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if(block) block(error);
    }];
    
    [self.requestConnection start];
}

- (void)deletePhotoLikeWithPhotoID:(NSString *)photoID
                   completionBlock:(void (^)(NSError *error))block
{
    if (self.requestConnection) {
        [self.requestConnection cancel];
        self.requestConnection = nil;
        self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    }
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoID] parameters:nil HTTPMethod:@"DELETE"];
    
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if(block) block(error);
    }];
    
    [self.requestConnection start];
}

#pragma mark - Private Methods

- (void)addNamesAndIdsFromArrayOfFacebookResponses:(NSArray *)responses forKey:(NSString *)key {
    NSMutableArray *namesAndIds = [NSMutableArray new];
    for (NSDictionary *dict in self.allNameAndIdResponsesForAlbum) {
        NSArray *photoCaptionArray = [dict valueForKeyPath:@"name"];
        NSArray *photoIdArray = [dict valueForKey:@"id"];
        NSArray *photoLikesCountArray = [dict valueForKeyPath:@"likes.summary.total_count"];
        NSArray *photoCommentCountArray = [dict valueForKeyPath:@"comments.summary.total_count"];
        for (int i = 0; i < photoIdArray.count; i++) {
            NSString *captionAtIndex = photoCaptionArray[i];
            if (![captionAtIndex isEqual:[NSNull null]]) {
                NSArray *lines = [captionAtIndex componentsSeparatedByString:@"\n"];
                NSString *name = lines.firstObject;
                FTFImage *photo = [FTFImage new];
                photo.photographerName = name;
                photo.photoID = photoIdArray[i];
                photo.likesCount = [photoLikesCountArray[i] integerValue];
                photo.commentCount = [photoCommentCountArray[i] integerValue];
                for (NSString *string in lines) {
                    if ([string containsString:@"Shutter: "]) {
                        NSArray *splitElements = [string componentsSeparatedByString:@" "];
                        NSMutableString *fraction = [[NSMutableString alloc] initWithString:splitElements[1]];
                        if ([fraction isEqualToString:@"1"]) {
                            photo.shutterSpeed = [fraction doubleValue];
                            photo.shutterSpeedString = fraction;
                            continue;
                        }
                        [fraction deleteCharactersInRange:NSMakeRange(fraction.length - 2, 2)];
                        NSArray *splitFraction = [fraction componentsSeparatedByString:@"/"];
                        double numerator = [splitFraction.firstObject doubleValue];
                        double denominator = [splitFraction.lastObject doubleValue];
                        photo.shutterSpeed = numerator / denominator;
                        NSArray *splitString = [string componentsSeparatedByString:@": "];
                        photo.shutterSpeedString = splitString.lastObject;
                        continue;
                    }
                    if ([string containsString:@"Aperture: "]) {
                        NSArray *splitElements = [string componentsSeparatedByString:@"/"];
                        if ([splitElements[1] containsString:@" "]) {
                            NSArray *split = [splitElements[1] componentsSeparatedByString:@" "];
                            photo.aperture = [split.firstObject doubleValue];
                        } else {
                            NSString *apertureNumberString = splitElements[1];
                            photo.aperture = [apertureNumberString doubleValue];
                        }
                        NSArray *splitString = [string componentsSeparatedByString:@": "];
                        photo.apertureString = splitString.lastObject;
                        continue;
                    }
                    if ([string containsString:@"ISO: "]) {
                        NSArray *splitElements = [string componentsSeparatedByString:@": "];
                        if ([splitElements.lastObject containsString:@"and"]) {
                            NSArray *split = [splitElements.lastObject componentsSeparatedByString:@" "];
                            photo.ISO = [split.firstObject integerValue];
                        } else {
                            photo.ISO = [splitElements.lastObject integerValue];
                        }
                        photo.isoString = splitElements.lastObject;
                        continue;
                    }
                    if ([string containsString:@"Critique: "]) {
                        if ([string containsString:@"52F-CC Regular"]) {
                            photo.critiqueType = FTFImageCritiqueTypeRegular;
                        } else if ([string containsString:@"SHRED AWAY!"]) {
                            photo.critiqueType = FTFImageCritiqueTypeShredAway;
                        } else if ([string containsString:@"sensitive"]) {
                            photo.critiqueType = FTFImageCritiqueTypeExtraSensitive;
                        } else {
                            photo.critiqueType = FTFImageCritiqueTypeNotInterested;
                        }
                        continue;
                    }
                    if ([string containsString:@"Lens: "]) {
                        NSArray *splitElements = [string componentsSeparatedByString:@"@"];
                        NSString *focalLengthString = splitElements.lastObject;
                        photo.focalLength = [focalLengthString integerValue];
                    }
                    
                    if ([string containsString:@"This photo qualifies for the"]) {
                        photo.qualifiesForExtraCreditChallenge = YES;
                        continue;
                    }
                    if ([string containsString:@"This is my FIRST submission"]) {
                        photo.fromNewFramer = YES;
                        continue;
                    }
                }
                
                [namesAndIds addObject:photo];
            }
        }
    }
    [self.albumIdsToNameAndIdsArrays setObject:[namesAndIds copy] forKey:key];
}

- (NSString *)graphPathFromFilteredNamesAndIds:(NSArray *)namesAndIds {
    NSMutableString *photoIdsForFacebookQuery = [NSMutableString new];
    int count = namesAndIds.count <= 50 ? (int)namesAndIds.count : 50;
    for (int i = 0; i < count; i++) {
        BOOL shouldIgnoreComma = count - i == 1;
        FTFImage *photo = namesAndIds[i];
        [photoIdsForFacebookQuery appendString:shouldIgnoreComma ? photo.photoID : [photo.photoID stringByAppendingString:@","]];
    }
    
    return [NSString stringWithFormat:@"?ids=%@", photoIdsForFacebookQuery];
}

- (void)namesAndIdsForFilters:(NSDictionary *)filters albumId:(NSString *)albumId completionBlock:(void (^)(NSArray *namesAndIds, NSError *error))block {
    
    NSError *noMatchesFoundError = [NSError errorWithDomain:@"com.52Frames" code:100 userInfo:@{@"message" : @"Couldn't find photos that match your criteria."}];
    
    if (self.albumIdsToNameAndIdsArrays[albumId]) {
        self.filteredNamesAndIds = [self filteredNamesAndIdsForFilters:filters albumId:albumId];
        if (self.filteredNamesAndIds.count == 0) {
            block(nil, noMatchesFoundError);
            return;
        }
        
        NSMutableArray *arraysOfFilteredNamesAndIds = [NSMutableArray new];
        NSInteger index = 0;
        NSInteger count = 50;
        while (index < self.filteredNamesAndIds.count) {
            if (self.filteredNamesAndIds.count - index <= 50) {
                count = self.filteredNamesAndIds.count - index;
            }
            [arraysOfFilteredNamesAndIds addObject:[self.filteredNamesAndIds subarrayWithRange:NSMakeRange(index, count)]];
            index += 50;
        }
        self.filteredNamesAndIds = [arraysOfFilteredNamesAndIds copy];
        block(self.filteredNamesAndIds[_pagingIndexForFilteredResults], nil);
        
    } else {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:self.graphPathForNameSearch parameters:self.parametersForNameSearch] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            NSString *nextPage = [result valueForKeyPath:@"paging.next"];
            [self.allNameAndIdResponsesForAlbum addObject:[result valueForKey:@"data"]];
            if (nextPage == NULL) {
                [self addNamesAndIdsFromArrayOfFacebookResponses:[self.allNameAndIdResponsesForAlbum copy] forKey:albumId];
                self.allNameAndIdResponsesForAlbum = nil;
                
                self.filteredNamesAndIds = [self filteredNamesAndIdsForFilters:filters albumId:albumId];
                if (self.filteredNamesAndIds.count == 0) {
                    block(nil, noMatchesFoundError);
                    return;
                }
                
                NSMutableArray *arraysOfFilteredNamesAndIds = [NSMutableArray new];
                NSInteger index = 0;
                NSInteger count = 50;
                while (index < self.filteredNamesAndIds.count) {
                    if (self.filteredNamesAndIds.count - index <= 50) {
                        count = self.filteredNamesAndIds.count - index;
                    }
                    [arraysOfFilteredNamesAndIds addObject:[self.filteredNamesAndIds subarrayWithRange:NSMakeRange(index, count)]];
                    index += 50;
                }
                self.filteredNamesAndIds = [arraysOfFilteredNamesAndIds copy];
                block(self.filteredNamesAndIds[_pagingIndexForFilteredResults], nil);
                
            } else {
                self.graphPathForNameSearch = [nextPage substringFromIndex:31];
                if (self.parametersForNameSearch) {
                    self.parametersForNameSearch = nil;
                }
                [self namesAndIdsForFilters:filters albumId:albumId completionBlock:block];
                NSLog(@"Fetching another 100 photos");
            }
        }];
    }
}

- (NSArray *)filteredNamesAndIdsForFilters:(NSDictionary *)filters albumId:(NSString *)albumId {
    if (!self.albumIdsToNameAndIdsArrays[albumId]) {
        return nil;
    }
    
    NSArray *namesAndIds = self.albumIdsToNameAndIdsArrays[albumId];
    NSArray *filteredArray = [self filteredArray:namesAndIds withFilters:filters];
    FTFSortOrder sortOrder = (FTFSortOrder)[filters[@"sortOrder"] integerValue];
    return [self sortedArray:filteredArray withSortOrder:sortOrder];
}

- (NSArray *)sortedArray:(NSArray *)arrayToSort withSortOrder:(FTFSortOrder)sortOrder {
    NSArray *sortedArray;
    if (sortOrder != FTFSortOrderNone) {
        NSString *sortKey;
        if (sortOrder == FTFSortOrderLikes) {
            sortKey = @"likesCount";
        } else if (sortOrder == FTFSortOrderComments) {
            sortKey = @"commentCount";
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:NO];
        sortedArray = [arrayToSort sortedArrayUsingDescriptors:@[sortDescriptor]];
    } else {
        sortedArray = arrayToSort;
    }
    
    return sortedArray;
}

- (NSArray *)filteredArray:(NSArray *)arrayToFilter withFilters:(NSDictionary *)filters {
    NSMutableArray *andPredicates = [NSMutableArray new];
    NSMutableArray *critiqueTypePredicates = [NSMutableArray new];
    
    if (![filters[@"apertureLowerValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aperture >= %@", filters[@"apertureLowerValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"apertureUpperValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aperture <= %@", filters[@"apertureUpperValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"focalLengthLowerValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"focalLength >= %@", filters[@"focalLengthLowerValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"focalLengthUpperValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"focalLength <= %@", filters[@"focalLengthUpperValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"ISOLowerValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ISO >= %@", filters[@"ISOLowerValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"ISOUpperValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ISO <= %@", filters[@"ISOUpperValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"shutterSpeedLowerValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"shutterSpeed >= %@", filters[@"shutterSpeedLowerValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"shutterSpeedUpperValue"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"shutterSpeed <= %@", filters[@"shutterSpeedUpperValue"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"extraCreditChallenge"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"qualifiesForExtraCreditChallenge == %@", filters[@"extraCreditChallenge"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"newFramers"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromNewFramer == %@", filters[@"newFramers"]];
        [andPredicates addObject:predicate];
    }
    
    if (![filters[@"critiqueTypeRegular"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"critiqueType == %@", filters[@"critiqueTypeRegular"]];
        [critiqueTypePredicates addObject:predicate];
    }
    
    if (![filters[@"critiqueTypeShredAway"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"critiqueType == %@", filters[@"critiqueTypeShredAway"]];
        [critiqueTypePredicates addObject:predicate];
    }
    
    if (![filters[@"critiqueTypeExtraSensitive"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"critiqueType == %@", filters[@"critiqueTypeExtraSensitive"]];
        [critiqueTypePredicates addObject:predicate];
    }
    
    if (![filters[@"critiqueTypeNotInterested"] isEqualToNumber:@0]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"critiqueType == %@", filters[@"critiqueTypeNotInterested"]];
        [critiqueTypePredicates addObject:predicate];
    }
    
    if (![filters[@"searchTerm"] isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photographerName CONTAINS %@", filters[@"searchTerm"]];
        [andPredicates addObject:predicate];
    }
    
    NSCompoundPredicate *finalPredicate;
    
    if (andPredicates.count == 0) {
        if (critiqueTypePredicates.count == 0) {
            return arrayToFilter;
        } else {
            finalPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:critiqueTypePredicates];
        }
    } else {
        if (critiqueTypePredicates.count == 0) {
            finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:andPredicates];
        } else {
            NSCompoundPredicate *orPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:critiqueTypePredicates];
            NSCompoundPredicate *andPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:andPredicates];
            finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[andPredicate, orPredicate]];
        }
    }
    
    return [arrayToFilter filteredArrayUsingPredicate:finalPredicate];
}

@end

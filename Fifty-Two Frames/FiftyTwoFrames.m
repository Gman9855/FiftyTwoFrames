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

@property (nonatomic, strong) NSMutableArray *weeklyThemeAlbums;
@property (nonatomic, strong) NSMutableArray *photoWalkAlbums;
@property (nonatomic, strong) NSMutableArray *miscellaneousAlbums;

@property (nonatomic, strong, readwrite) FTFUser *user;

@end

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
        _photoRequestParameters = @{@"fields" : @"images,id,name,likes.limit(1).summary(true).fields(has_liked),comments.fields(from.fields(picture.type(large),id,name),created_time,message)"};
    }
    
    return _photoRequestParameters;
}

- (NSDictionary *)parametersForNameSearch {
    if (!_parametersForNameSearch) {
        _parametersForNameSearch = [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"fields", nil];
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
                NSArray *albumPhotos = [weakSelf albumPhotosWithAlbumPhotoResponseData:[result valueForKey:@"data"]];
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

- (void)requestNextPageOfAlbumPhotosWithCompletionBlock:(void (^)(NSArray *photos, NSError *error, BOOL finishedPaging))block {
    if (self.requestConnection) {
        [self.requestConnection cancel];
        self.requestConnection = nil;
    }
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:self.nextPageOfAlbumPhotoResultsURL parameters:nil];
    self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        NSString *nextPage = [result valueForKeyPath:@"paging.next"];
        NSArray *nextBatchOfAlbumPhotos = [weakSelf albumPhotosWithAlbumPhotoResponseData:[result valueForKey:@"data"]];
        if (nextPage == NULL) {
            block(nextBatchOfAlbumPhotos, nil, YES);
        } else {
            weakSelf.nextPageOfAlbumPhotoResultsURL = [nextPage substringFromIndex:31];
            block(nextBatchOfAlbumPhotos, nil, NO);
        }
    }];
    
    [self.requestConnection start];
}

- (void)requestAlbumPhotosForPhotographerSearchTerm:(NSString *)searchTerm albumId:(NSString *)albumId completionBlock:(void (^)(NSArray *photos, NSError *error))block {
    __weak typeof(self) weakSelf = self;
    
    [self namesAndIdsForPhotographerSearchTerm:searchTerm albumId:albumId completionBlock:^(NSArray *namesAndIds, NSError *error) {
        if (error) {
            block(nil, error);
            return;
        }
        NSString *graphPath = [self graphPathFromFilteredNamesAndIds:namesAndIds];

        [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:self.photoRequestParameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (block) {
                if (!error) {
                    NSMutableArray *albumPhotos = [NSMutableArray new];
                    for (FTFImage *photo in namesAndIds) {
                        NSString *photoId = photo.photoID;
                        NSArray *parsedPhoto = [weakSelf albumPhotosWithAlbumPhotoResponseData:[result valueForKey:photoId]];
                        if (parsedPhoto.count > 0) {
                            [albumPhotos addObject:(FTFImage *)parsedPhoto.firstObject];
                        }
                    }
                    block(albumPhotos, nil);
                    
                } else {
                    block(nil, error);
                }
            } else {
                return;
            }
        }];
    }];
}

- (void)publishPhotoCommentWithPhotoID:(NSString *)photoID comment:(NSString *)comment completionBlock:(void (^)(NSError *error))block
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            comment, @"message",
                            nil];
    
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

- (NSArray *)albumPhotosWithAlbumPhotoResponseData:(NSDictionary *)dict {
    NSArray *photoCollections;
    NSArray *photoDescriptionCollection;
    NSArray *likesCountCollection;
    NSArray *commentsCollection;
    NSArray *userHasLikedPhotoCollection;
    NSArray *photoIDs = [dict valueForKeyPath:@"id"];
    if ([photoIDs isKindOfClass:[NSString class]]) {
        photoIDs = @[[dict valueForKeyPath:@"id"]];
        photoCollections = @[[dict valueForKeyPath:@"images"]];
        photoDescriptionCollection = @[[dict valueForKeyPath:@"name"]];
        likesCountCollection = @[[dict valueForKeyPath:@"likes.summary.total_count"]];
        if ([dict valueForKeyPath:@"comments.data"]) {
            commentsCollection = @[[dict valueForKeyPath:@"comments.data"]];
        }
        userHasLikedPhotoCollection = @[[dict valueForKeyPath:@"likes.summary.has_liked"]];
    } else {
        photoCollections = [dict valueForKeyPath:@"images"];
        photoDescriptionCollection = [dict valueForKeyPath:@"name"];
        likesCountCollection = [dict valueForKeyPath:@"likes.summary.total_count"];
        commentsCollection = [dict valueForKeyPath:@"comments.data"];
        userHasLikedPhotoCollection = [dict valueForKeyPath:@"likes.summary.has_liked"];
    }
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [photoCollections count]; i++) {
        NSArray *array = photoCollections[i];
        NSDictionary *largePhotoDict = array.firstObject;
        
        NSDictionary *smallPhotoDict = [self preferredSmallPhotoURLDictFromPhotoArray:photoCollections[i]];
        
//        NSArray *imageURLs = [self urlsFromPhotoArray:photoCollections[i]];
        NSString *largePhotoStringURL = [largePhotoDict valueForKey:@"source"];
        NSString *smallPhotoStringURL = [smallPhotoDict valueForKey:@"source"];
        
        NSURL *largePhotoURL = [NSURL URLWithString:largePhotoStringURL];
        NSURL *smallPhotoURL = [NSURL URLWithString:smallPhotoStringURL];
        
        FTFImage *image = [[FTFImage alloc] initWithImageURLs:@[largePhotoURL, smallPhotoURL]];
        
        CGFloat smallPhotoWidth = [[smallPhotoDict valueForKey:@"width"] floatValue];
        CGFloat smallPhotoHeight = [[smallPhotoDict valueForKey:@"height"] floatValue];
        
        CGFloat largePhotoWidth = [[largePhotoDict valueForKey:@"width"] floatValue];
        CGFloat largePhotoHeight = [[largePhotoDict valueForKey:@"height"] floatValue];
        
        image.smallPhotoSize = CGSizeMake(smallPhotoWidth, smallPhotoHeight);
        image.largePhotoSize = CGSizeMake(largePhotoWidth, largePhotoHeight);
            
        BOOL containsPhotoDescription = ![photoDescriptionCollection[i] isEqual:[NSNull null]];
        NSString *photoTitle;
        if (containsPhotoDescription) {
            NSArray *lines = [photoDescriptionCollection[i] componentsSeparatedByString:@"\n"];
            for (NSString *string in lines) {
                if (string.length > 0) {                //the string starting with a " is the title of the photo
                    NSString *firstLetter = [string substringToIndex:1];
                    if ([firstLetter isEqualToString:@"\""]) {
                        photoTitle = string;
                        break;
                    }
                }
            }
            
            image.title = photoTitle.length > 0 ? [[photoTitle stringByReplacingOccurrencesOfString:@"\"" withString:@""] capitalizedString] : [lines[0] capitalizedString];
            image.photographerName = [lines[0] capitalizedString];
            image.photoDescription = photoDescriptionCollection[i];
        }

        image.likesCount = [likesCountCollection[i]integerValue];
        image.photoID = photoIDs[i];
                
        image.isLiked = [userHasLikedPhotoCollection[i] intValue];
        NSArray *photoComments = commentsCollection[i];
        NSMutableArray *arrayOfphotoCommentObjects = [NSMutableArray new];
        if (photoComments != (id)[NSNull null]) {
            for (NSDictionary *comment in photoComments) {
                FTFPhotoComment *photoComment = [FTFPhotoComment new];
                photoComment.commenterName = [comment valueForKeyPath:@"from.name"];
                photoComment.commenterID = [comment valueForKeyPath:@"from.id"];
                NSString *commentDate = [comment valueForKey:@"created_time"];
                photoComment.createdTime = [self formattedDateStringFromFacebookDate:commentDate];
                photoComment.likeCount = [comment valueForKey:@"like_count"];
                photoComment.comment = [comment valueForKey:@"message"];
                photoComment.commenterProfilePictureURL = [NSURL URLWithString:[comment valueForKeyPath:@"from.picture.data.url"]];
                [arrayOfphotoCommentObjects addObject:photoComment];
            }
            NSSortDescriptor *createdTimeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdTime" ascending:YES];
            image.comments = [[arrayOfphotoCommentObjects sortedArrayUsingDescriptors:@[createdTimeSortDescriptor]] copy];
        }
        [objects addObject:image];
    }
    return objects;
}

- (NSDate *)formattedDateStringFromFacebookDate:(NSString *)fbDate {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
    });

    return [dateFormatter dateFromString:fbDate];
}

- (NSArray *)urlsFromPhotoArray:(NSArray *)array;
{
    NSString *largeImageURL = [self sourceOfImageData:[array firstObject]];
    NSString *smallImageURL;
    for (NSDictionary *dict in array) {
        smallImageURL = largeImageURL;
        NSInteger imageHeight = [[dict valueForKeyPath:@"height"]intValue];
        if (imageHeight <= 500 && imageHeight >= 350) {
            smallImageURL = [self sourceOfImageData:dict];
            break;
        }
    }
    
    return [@[largeImageURL,
              smallImageURL] map:^id(id object, NSUInteger index) {
                  return [NSURL URLWithString:object];
              }];
}

- (NSDictionary *)preferredSmallPhotoURLDictFromPhotoArray:(NSArray *)array {
    NSDictionary *smallImageDict = [array firstObject];
    for (NSDictionary *dict in array) {
        NSInteger imageHeight = [[dict valueForKeyPath:@"height"]intValue];
        if (imageHeight <= 500 && imageHeight >= 350) {
            smallImageDict = dict;
            break;
        }
    }
    
    return smallImageDict;
}

- (NSString *)sourceOfImageData:(NSDictionary *)data;
{
    return [data valueForKeyPath:@"source"];
}

- (void)addNamesAndIdsFromArrayOfFacebookResponses:(NSArray *)responses forKey:(NSString *)key {
    NSMutableArray *namesAndIds = [NSMutableArray new];
    for (NSDictionary *dict in self.allNameAndIdResponsesForAlbum) {
        NSArray *photoCaptionArray = [dict valueForKeyPath:@"name"];
        NSArray *photoIdArray = [dict valueForKey:@"id"];
        for (int i = 0; i < photoIdArray.count; i++) {
            NSString *nameAtIndex = photoCaptionArray[i];
            if (![nameAtIndex isEqual:[NSNull null]]) {
                NSArray *lines = [nameAtIndex componentsSeparatedByString:@"\n"];
                NSString *name = lines.firstObject;
                FTFImage *photo = [FTFImage new];
                photo.photographerName = name;
                photo.photoID = photoIdArray[i];
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

- (void)namesAndIdsForPhotographerSearchTerm:(NSString *)searchTerm albumId:(NSString *)albumId completionBlock:(void (^)(NSArray *namesAndIds, NSError *error))block {
    
    NSError *noMatchesFoundError = [NSError errorWithDomain:@"com.52Frames" code:100 userInfo:@{@"message" : @"Couldn't find photos that match your search term."}];
    
    if (self.albumIdsToNameAndIdsArrays[albumId]) {
        NSArray *filtered = [self filteredNamesAndIdsForSearchTerm:searchTerm albumId:albumId];
        if (filtered.count == 0) {
            block(nil, noMatchesFoundError);
            return;
        }
        
        block(filtered, nil);
    } else {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:self.graphPathForNameSearch parameters:self.parametersForNameSearch] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            NSString *nextPage = [result valueForKeyPath:@"paging.next"];
            [self.allNameAndIdResponsesForAlbum addObject:[result valueForKey:@"data"]];
            if (nextPage == NULL) {
                [self addNamesAndIdsFromArrayOfFacebookResponses:[self.allNameAndIdResponsesForAlbum copy] forKey:albumId];
                self.allNameAndIdResponsesForAlbum = nil;
                NSArray *filtered = [self filteredNamesAndIdsForSearchTerm:searchTerm albumId:albumId];
                if (filtered.count == 0) {
                    block(nil, noMatchesFoundError);
                    return;
                }
                
                block(filtered, nil);
            } else {
                self.graphPathForNameSearch = [nextPage substringFromIndex:31];
                if (self.parametersForNameSearch) {
                    self.parametersForNameSearch = nil;
                }
                [self namesAndIdsForPhotographerSearchTerm:searchTerm albumId:albumId completionBlock:block];
                NSLog(@"Fetching another 100 photos");
            }
        }];
    }
}

- (NSArray *)filteredNamesAndIdsForSearchTerm:(NSString *)searchTerm albumId:(NSString *)albumId {
    if (!self.albumIdsToNameAndIdsArrays[albumId]) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photographerName CONTAINS %@", searchTerm];
    NSArray *namesAndIds = self.albumIdsToNameAndIdsArrays[albumId];
    NSArray *filtered = [namesAndIds filteredArrayUsingPredicate:predicate];
    return filtered;
}

@end

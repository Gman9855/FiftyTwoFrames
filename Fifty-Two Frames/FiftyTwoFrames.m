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

@interface FiftyTwoFrames ()

@property (nonatomic, strong) FBSDKGraphRequestConnection *requestConnection;

@property (nonatomic, strong) NSString *nextPageOfAlbumsURL;
@property (nonatomic, strong) NSString *nextPageOfAlbumPhotoResultsURL;

@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) NSMutableDictionary *albumResultsFromFacebook;
@property (nonatomic, strong) NSMutableArray *albumDicts;
@property (nonatomic, strong) NSMutableArray *albumPhotoDicts;

@property (nonatomic, strong) NSMutableArray *weeklyThemeAlbums;
@property (nonatomic, strong) NSMutableArray *photoWalkAlbums;
@property (nonatomic, strong) NSMutableArray *miscellaneousAlbums;

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

#pragma mark - Public Methods

- (void)requestUserWithCompletionBlock:(void (^)(FTFUser *user, NSError *error))block {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"id, name, picture.fields(url)", @"fields", nil];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            self.user = [self userWithResponseData:result];
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
    NSString *graphPath = @"/180889155269546";
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            block(nil, error, YES);
        } else {
            FTFAlbumCategoryCollection *categoryCollection = [[FTFAlbumCategoryCollection alloc] initWithAlbumCollections:[self albumsWithAlbumResponseData:@[result]]];
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
    
    NSString *graphPath = @"/180889155269546?albums.limit(50)";
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (block) {
            __block FTFAlbumCategoryCollection *albumCategoryCollection = nil;
            if (!error) {
                self.albumDicts = [NSMutableArray new];
                [self.albumDicts addObject:result];
                NSString *nextPage = [result valueForKeyPath:@"albums.paging.next"];
                self.nextPageOfAlbumsURL = [nextPage substringFromIndex:31];
                [self requestRemainingAlbumsWithCompletionBlock:^(NSArray *albums, NSError *error) {
                    if (error) {
                        block(nil, error);
                    } else {
                        albumCategoryCollection = [[FTFAlbumCategoryCollection alloc] initWithAlbumCollections:albums];
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
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"images,id,name,likes.limit(1).summary(true).fields(has_liked),comments.fields(from.fields(picture.type(large),id,name),created_time,message)", @"fields", nil];
    
    self.requestConnection = [[FBSDKGraphRequestConnection alloc] init];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:params];
    __weak typeof(self) weakSelf = self;
    [self.requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (block) {
            if (!error) {
                NSArray *albumPhotos = [weakSelf albumPhotosWithAlbumPhotoResponseData:result];
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

- (void)requestRemainingAlbumsWithCompletionBlock:(void (^)(NSArray *albums, NSError *error))block {
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
                NSArray *allAlbums = [self albumsWithAlbumResponseData:self.albumDicts];
                block(allAlbums, nil);
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
        NSArray *nextBatchOfAlbumPhotos = [weakSelf albumPhotosWithAlbumPhotoResponseData:result];
        if (nextPage == NULL) {
            block(nextBatchOfAlbumPhotos, nil, YES);
        } else {
            weakSelf.nextPageOfAlbumPhotoResultsURL = [nextPage substringFromIndex:31];
            block(nextBatchOfAlbumPhotos, nil, NO);
        }
    }];
    
    [self.requestConnection start];
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

- (FTFUser *)userWithResponseData:(NSDictionary *)response {
    FTFUser *user = [FTFUser new];
    user.name = [response valueForKey:@"name"];
    user.userID = [response valueForKey:@"id"];
    user.profilePictureURL = [NSURL URLWithString:[response valueForKeyPath:@"picture.data.url"]];
    return user;
}

- (NSArray *)albumsWithAlbumResponseData:(NSArray *)response {
    NSMutableArray *weeklyThemeAlbums = [NSMutableArray new];
    NSMutableArray *photoWalkAlbums = [NSMutableArray new];
    NSMutableArray *miscellaneousAlbums = [NSMutableArray new];
    
    for (NSDictionary *dict in response) {
        
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

- (NSArray *)albumPhotosWithAlbumPhotoResponseData:(NSDictionary *)dict {
    NSArray *photoIDs = [dict valueForKeyPath:@"data.id"];
    NSArray *photoCollections = [dict valueForKeyPath:@"data.images"];
    NSArray *photoDescriptionCollection = [dict valueForKeyPath:@"data.name"];
    NSArray *likesCountCollection = [dict valueForKeyPath:@"data.likes.summary.total_count"];
    NSArray *commentsCollection = [dict valueForKeyPath:@"data.comments.data"];
    NSArray *userHasLikedPhotoCollection = [dict valueForKeyPath:@"data.likes.summary.has_liked"];
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [photoCollections count]; i++) {
        NSArray *imageURLs = [self urlsFromPhotoArray:photoCollections[i]];
        FTFImage *image = [[FTFImage alloc] initWithImageURLs:imageURLs];
        BOOL containsPhotoDescription = ![photoDescriptionCollection[i] isEqual:[NSNull null]];
        NSString *photoTitle;
        if (containsPhotoDescription) {
            NSArray *lines = [photoDescriptionCollection[i] componentsSeparatedByString:@"\n"];
            for (NSString *string in lines) {
                if (string.length > 0) {                //the string starting with a " is the title of the photo
                    NSString *firstLetter = [string substringToIndex:1];
                    if ([firstLetter isEqualToString:@"\""]) {
                        photoTitle = string;
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

- (NSString *)sourceOfImageData:(NSDictionary *)data;
{
    return [data valueForKeyPath:@"source"];
}
@end

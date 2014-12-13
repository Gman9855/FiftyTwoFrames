//
//  FTFFacebook.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>

#import "FiftyTwoFrames.h"

#import "FTFAlbumCategoryCollection.h"
#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import "FTFPhotoComment.h"
#import "FTFUser.h"
#import "TTTTimeIntervalFormatter.h"

#import "SDWebImageManager.h"

@interface FiftyTwoFrames ()

@property (nonatomic, strong) FBRequestConnection *requestConnection;
@property (nonatomic, strong) NSString *nextPageOfALbumPhotoResultsURLString;

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
        [self requestUserWithCompletionBlock:^(FTFUser *user) {
            done = YES;
        }];
    
        while (!done) [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    return _user;
}

#pragma mark - Public Methods

- (void)requestUserWithCompletionBlock:(void (^)(FTFUser *user))block {

    [FBRequestConnection startWithGraphPath:@"/me?fields=id,name,picture.fields(url)"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (block) {
                                  if (!error) {
                                      self.user = [self userWithResponseData:result];
                                      block(self.user);
                                  }
                              }
                          }];
}

- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCategoryCollection *, NSError *))block;
{
    [FBRequestConnection startWithGraphPath:@"/180889155269546?fields=albums.limit(10000).fields(name,photos.limit(1).fields(picture))"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              if (block) {
                                  FTFAlbumCategoryCollection *albumCategoryCollection = nil;
                                  if (!error) {
                                      NSArray *albums = [self albumsWithAlbumResponseData:result];
                                      albumCategoryCollection = [[FTFAlbumCategoryCollection alloc] initWithAlbumCollections:albums];
                                  }
                                  
                                  block(albumCategoryCollection, error);
                              } else {
                                  return;
                              }
                          }];
}

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID
                                        limit:(NSInteger)limit
                                 completionBlock:(void (^)(NSArray *photos, NSError *error))block
{
    [self.requestConnection cancel];
 //   833602159998239/photos?fields=comments.fields(from.fields(picture,id,name))
    self.requestConnection = [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/photos?limit=50&fields=images,id,name,likes.limit(1).summary(true),comments.fields(from.fields(picture.type(large),id,name),created_time,message)", albumID]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              if (block) {
                                  if (!error) {
                                      NSArray *albumPhotos = [self albumPhotosWithAlbumPhotoResponseData:result];
                                      self.nextPageOfALbumPhotoResultsURLString = [result valueForKeyPath:@"paging.next"];
                                      block(albumPhotos, nil);
                                  } else {
                                      block(nil, error);
                                  }
                              } else {
                                  return;
                              }
                          }];
}

- (void)requestNextPageOfAlbumPhotosWithCompletionBlock:(void (^)(NSArray *photos, NSError *error))block {
    FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:nil];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (block) {
            if (!error) {
                NSArray *albumPhotos = [self albumPhotosWithAlbumPhotoResponseData:result];
                self.nextPageOfALbumPhotoResultsURLString = [result valueForKeyPath:@"paging.next"];
                NSLog(@"%@", self.nextPageOfALbumPhotoResultsURLString);
                block(albumPhotos, nil);
            } else {
                block(nil, error);
            }
        } else {
            return;
        }
    }];
    
    // Override the URL using the one passed back in 'next|previous'.
    NSURL *url = [NSURL URLWithString:self.nextPageOfALbumPhotoResultsURLString];
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    connection.urlRequest = urlRequest;
    [connection start];
}

- (void)requestPhotoWithPhotoURL:(NSURL *)photoURL
                completionBlock:(void (^)(UIImage *, NSError *, BOOL))block
{
    NSParameterAssert(block);
    
    if (!photoURL) {
        block(nil, nil, NO);
        return;
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    UIImage *cachedImage = [manager.imageCache imageFromMemoryCacheForKey:photoURL.absoluteString];
    if (cachedImage) {
        block(cachedImage, nil, YES);
        return;
    }
    
    [manager downloadWithURL:photoURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        if (finished && photoURL) {
            [manager saveImageToCache:image forURL:photoURL];
        }
        
        block(image, error, NO);
    }];
}

- (void)publishPhotoCommentWithPhotoID:(NSString *)photoID comment:(NSString *)comment completionBlock:(void (^)(NSError *error))block
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            comment, @"message",
                            nil];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/comments", photoID]
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              block(error);
                          }];
}

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID
                    completionBlock:(void (^)(NSError *))block
{
    [self.requestConnection cancel];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoID]
                                 parameters:nil
                                 HTTPMethod:@"POST"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if(block) block(error);
                          }];
}

- (void)deletePhotoLikeWithPhotoID:(NSString *)photoID
                   completionBlock:(void (^)(NSError *error))block
{
    [self.requestConnection cancel];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/likes", photoID]
                                 parameters:nil
                                 HTTPMethod:@"DELETE"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if(block) block(error);
                          }];
}

#pragma mark - Private Methods

- (FTFUser *)userWithResponseData:(NSDictionary *)response {
    FTFUser *user = [FTFUser new];
    user.name = [response valueForKey:@"name"];
    user.userID = [response valueForKey:@"id"];
    user.profilePictureURL = [NSURL URLWithString:[response valueForKeyPath:@"picture.data.url"]];
    return user;
}

- (NSArray *)albumsWithAlbumResponseData:(NSDictionary *)response {
    NSArray *albumInfoDicts = [response valueForKeyPath:@"albums.data"];
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
        NSArray *source = array[0];
        NSMutableArray *destination = array[1];
        
        for (NSDictionary *dict in source) {
            FTFAlbum *album = [FTFAlbum new];
            album.name = [dict valueForKey:@"name"];
            album.albumID = [dict valueForKey:@"id"];
            NSArray *pictureURLstring = [dict valueForKeyPath:@"photos.data.picture"];
            album.coverPhotoURL = [NSURL URLWithString:[pictureURLstring firstObject]];
            album.yearCreated = [[dict valueForKeyPath:@"created_time"]substringToIndex:4];
            if (album.coverPhotoURL) {
                [destination addObject:album];
            }
        }
    }
    
    FTFAlbumCollection *weeklyThemeCollection = [[FTFAlbumCollection alloc] initWithAlbums:weeklyThemeAlbums andCollectionCategory:FTFAlbumCollectionCategoryWeeklyThemes];
    FTFAlbumCollection *photoWalkCollection = [[FTFAlbumCollection alloc] initWithAlbums:photoWalkAlbums andCollectionCategory:FTFAlbumCollectionCategoryPhotoWalks];
    FTFAlbumCollection *miscellaneousCollection = [[FTFAlbumCollection alloc] initWithAlbums:miscellaneousAlbums andCollectionCategory:FTFAlbumCollectionCategoryMiscellaneous];
    
    return @[weeklyThemeCollection, photoWalkCollection, miscellaneousCollection];
}

- (NSArray *)albumPhotosWithAlbumPhotoResponseData:(NSDictionary *)response {
    NSArray *photoIDs = [response valueForKeyPath:@"data.id"];
    NSArray *photoCollections = [response valueForKeyPath:@"data.images"];
    NSArray *photoDescriptionCollection = [response valueForKeyPath:@"data.name"];
    NSArray *likesCountCollection = [response valueForKeyPath:@"data.likes.summary.total_count"];
    NSArray *commentsCollection = [response valueForKeyPath:@"data.comments.data"];
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [photoCollections count]; i++) {
        NSArray *imageURLs = [self urlsFromPhotoArray:photoCollections[i]];
        FTFImage *image = [[FTFImage alloc] initWithImageURLs:imageURLs];
        image.photoDescription = photoDescriptionCollection[i];
        image.photoLikesCount = [likesCountCollection[i]integerValue];
        image.photoID = photoIDs[i];
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
            image.photoComments = [arrayOfphotoCommentObjects copy];
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
    });

    [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
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

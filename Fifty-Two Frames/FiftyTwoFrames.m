//
//  FTFFacebook.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>

#import "FiftyTwoFrames.h"

#import "FTFAlbumCollection.h"
#import "FTFAlbum.h"
#import "FTFPhotoComment.h"

#import "SDWebImageManager.h"

@implementation FiftyTwoFrames

+ (instancetype)sharedInstance {
    static FiftyTwoFrames *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCollection *))block;
{
    [FBRequestConnection startWithGraphPath:@"/180889155269546?fields=albums.limit(10000).fields(name)"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              NSDictionary *fr = result;
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
                                  NSArray *source = array[0];
                                  NSMutableArray *destination = array[1];
                                  
                                  for (NSDictionary *dict in source) {
                                      FTFAlbum *album = [FTFAlbum new];
                                      album.name = [dict valueForKey:@"name"];
                                      album.albumID = [dict valueForKey:@"id"];
                                      album.yearCreated = [[dict valueForKey:@"created_time"]substringToIndex:4];
                                      [destination addObject:album];
                                  }
                              }
                              
                              if (block) {
                                  FTFAlbumCollection *albumCollection = [[FTFAlbumCollection alloc]
                                                                         initWithAlbums:@[weeklyThemeAlbums, photoWalkAlbums, miscellaneousAlbums]];
                                  block(albumCollection);
                              } else {
                                  return;
                              }
                          }];
}

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID
                                 completionBlock:(void (^)(NSArray *, NSError *))block
{
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=photos.limit(200)", albumID]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              if (error) {
                                  block(nil, error);
                                  return;
                              }
                              
                              NSArray *photoIDs = [result valueForKeyPath:@"photos.data.id"];
                              NSArray *photoCollections = [result valueForKeyPath:@"photos.data.images"];
                              NSArray *photoDescriptionCollection = [result valueForKeyPath:@"photos.data.name"];
                              NSArray *likesCollection = [result valueForKeyPath:@"photos.data.likes.data"];
                              NSArray *commentsCollection = [result valueForKeyPath:@"photos.data.comments.data"];
                              
                              NSMutableArray *objects = [NSMutableArray new];
                              
                              for (int i = 0; i < [photoCollections count]; i++) {
                                  NSArray *imageURLs = [self urlsFromPhotoArray:photoCollections[i]];
                                  FTFImage *image = [[FTFImage alloc] initWithImageURLs:imageURLs];
                                  image.photoDescription = photoDescriptionCollection[i];
                                  image.photoLikes = likesCollection[i];
                                  image.photoID = photoIDs[i];
                                  NSArray *photoComments = commentsCollection[i];
                                  NSMutableArray *arrayOfphotoCommentObjects = [NSMutableArray new];
                                  if (photoComments != (id)[NSNull null]) {
                                      for (NSDictionary *comment in photoComments) {
                                          FTFPhotoComment *photoComment = [FTFPhotoComment new];
                                          photoComment.commenterName = [comment valueForKeyPath:@"from.name"];
                                          photoComment.commenterID = [comment valueForKeyPath:@"from.id"];
                                          NSString *commentDate = [comment valueForKey:@"created_time"];
                                          photoComment.createdTime = [self formattedDateFromFacebookDate:commentDate];
                                          photoComment.likeCount = [comment valueForKey:@"like_count"];
                                          photoComment.comment = [comment valueForKey:@"message"];
                                          [arrayOfphotoCommentObjects addObject:photoComment];
                                      }
                                      image.photoComments = [arrayOfphotoCommentObjects copy];
                                  }
                                  [objects addObject:image];
                              }
                              
                              //self.photos = [objects copy];
                              if (block) block([objects copy], nil);
                          }];
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

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID
                    completionBlock:(void (^)(NSError *))block
{
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

- (NSDate *)formattedDateFromFacebookDate:(NSString *)fbDate {
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    [parser setTimeStyle:NSDateFormatterFullStyle];
    [parser setFormatterBehavior:NSDateFormatterBehavior10_4];
    [parser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
    return [parser dateFromString:fbDate];
    ;
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

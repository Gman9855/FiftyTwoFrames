//
//  FTFAlbum.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbum.h"
#import "FTFImage.h"
#import "FTFPhotoComment.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FTFAlbum ()

@end

@implementation FTFAlbum

- (void)retrieveAlbumPhotos:(void(^)(NSArray *photos, NSError *error))block;
{
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=photos.limit(200)", self.albumID]
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
                              
                              self.photos = [objects copy];
                              if (block) block(self.photos, nil);
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

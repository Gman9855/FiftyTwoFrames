//
//  FTFAlbum.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbum.h"
#import "FTFImage.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FTFAlbum ()

@property (nonatomic, strong) NSArray *photos;

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
                              NSArray *imageCollections = [result valueForKeyPath:@"photos.data.images"];
                              NSArray *photoDescriptionCollection = [result valueForKeyPath:@"photos.data.name"];
                              NSArray *likesCollection = [result valueForKeyPath:@"photos.data.likes.data"];
                              NSArray *commentsCollection = [result valueForKeyPath:@"photos.comments.data"];
                              
                              NSMutableArray *objects = [NSMutableArray new];
                              
                              for (int i = 0; i < [imageCollections count]; i++) {
                                  NSArray *imageURLs = [self urlsFromPhotoArray:imageCollections[i]];
                                  FTFImage *image = [[FTFImage alloc] initWithImageURLs:imageURLs];
                                  image.photoDescription = photoDescriptionCollection[i];
                                  image.photoLikes = likesCollection[i];
                                  image.photoComments = commentsCollection[i];
                                  [objects addObject:image];
                              }
                              
                              self.photos = [objects copy];
                              if (block) block(self.photos, nil);
                          }];

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

- (id)makeRequestForAlbumPhotos:(id)albumID;
{
    //    /180889155269546?fields=albums.limit(1).fields(photos.limit(200))
    __block id resultsData;
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=photos.limit(200)", albumID]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              /* handle the result */
                              resultsData = result;
                          }];
    return resultsData;
}

@end

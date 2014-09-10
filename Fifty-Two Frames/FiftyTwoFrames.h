//
//  FTFFacebook.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTFImage.h"

@class FTFAlbumCategoryCollection;

@interface FiftyTwoFrames : NSObject

+ (instancetype)sharedInstance;

- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCategoryCollection *, NSError *))block;

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID
                                        limit:(NSInteger)limit
                                 completionBlock:(void(^)(NSArray *photos, NSError *error))block;

- (void)requestPhotoWithPhotoURL:(NSURL *)photoURL
                completionBlock:(void (^)(UIImage *image, NSError *error, BOOL isCached))block;

- (void)requestAlbumCoverPhotoForAlbumCollection:(NSArray *)collection
                                 completionBlock:(void (^)(NSArray *coverPhotos, NSError *error))block;

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID
                    completionBlock:(void (^)(NSError *error))block;

- (void)publishPhotoCommentWithPhotoID:(NSString *)photoID
                   completionBlock:(void (^)(NSError *error))block;

@end

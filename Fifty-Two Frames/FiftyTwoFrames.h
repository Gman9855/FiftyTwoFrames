//
//  FTFFacebook.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTFImage.h"

@class FTFAlbumCollection;

@interface FiftyTwoFrames : NSObject

+ (instancetype)sharedInstance;

- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCollection *))block;

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID
                                 completionBlock:(void(^)(NSArray *photos, NSError *error))block;

- (void)requestPhotoWithPhotoURL:(NSURL *)photoURL
                completionBlock:(void (^)(UIImage *image, NSError *error, BOOL isCached))block;

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID completionBlock:(void (^)(NSError *error))block;

@end

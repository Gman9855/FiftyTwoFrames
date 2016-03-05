//
//  FTFFacebook.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/3/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTFImage.h"

@class FTFUser;
@class FTFAlbumCategoryCollection;
@class FTFAlbum;

@interface FiftyTwoFrames : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) FTFUser *user;


- (void)requestAlbumCollectionWithCompletionBlock:(void (^)(FTFAlbumCategoryCollection *, NSError *))block;

- (void)requestLatestWeeklyThemeAlbumWithCompletionBlock:(void (^)(FTFAlbum *album, NSError *error, BOOL finishedPaging))block;

- (void)requestAlbumPhotosForAlbumWithAlbumID:(NSString *)albumID completionBlock:(void(^)(NSArray *photos, NSError *error, BOOL finishedPaging))block;

- (void)requestNextPageOfAlbumPhotosWithCompletionBlock:(void (^)(NSArray *photos, NSError *error, BOOL finishedPaging))block;

- (void)publishPhotoLikeWithPhotoID:(NSString *)photoID
                    completionBlock:(void (^)(NSError *error))block;

- (void)deletePhotoLikeWithPhotoID:(NSString *)photoID
                   completionBlock:(void (^)(NSError *error))block;

- (void)publishPhotoCommentWithPhotoID:(NSString *)photoID
                               comment:(NSString *)comment
                       completionBlock:(void (^)(NSError *error))block;

- (void)requestUserWithCompletionBlock:(void (^)(FTFUser *user, NSError *error))block;

@end

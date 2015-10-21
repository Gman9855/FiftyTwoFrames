//
//  FTFImage.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

@class FTFPhotoComment;

#import <Foundation/Foundation.h>

typedef enum {
    FTFImageSizeLarge,
    FTFImageSizeSmall
} FTFImageSize;

@interface FTFImage : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *photographerName;
@property (nonatomic, strong) NSString *photoDescription;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) NSString *photoID;
@property (nonatomic, strong, readonly) NSURL *largePhotoURL;
@property (nonatomic, strong, readonly) NSURL *smallPhotoURL;
@property (nonatomic, assign) BOOL isLiked;

- (instancetype)initWithImageURLs:(NSArray *)imageURLs;
- (void)requestImageWithSize:(FTFImageSize)size completionBlock:(void(^)(UIImage *image, NSError *error, BOOL isCached))block;
- (void)cancel;
- (NSArray *)imageURLs;

- (void)addPhotoComment:(FTFPhotoComment *)photoComment;


@end

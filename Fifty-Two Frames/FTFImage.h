//
//  FTFImage.h
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FTFImageSizeLarge,
    FTFImageSizeSmall
} FTFImageSize;

@interface FTFImage : NSObject

@property (nonatomic, strong) NSString *photoDescription;
@property (nonatomic, strong) NSArray *photoLikes;
@property (nonatomic, strong) NSArray *photoComments;
@property (nonatomic, strong) NSString *photoID;
@property (nonatomic, strong, readonly) NSURL *largePhotoURL;
@property (nonatomic, strong, readonly) NSURL *smallPhotoURL;

- (instancetype)initWithImageURLs:(NSArray *)imageURLs;
- (void)requestImageWithSize:(FTFImageSize)size completionBlock:(void(^)(UIImage *image, NSError *error, BOOL isCached))block;
- (void)cancel;
- (NSArray *)imageURLs;

@end

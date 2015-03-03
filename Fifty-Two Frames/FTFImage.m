//
//  FTFImage.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

@class FTFPhotoComment;

#import "FTFImage.h"
#import "SDWebImageManager.h"

@interface FTFImage ()

@property (nonatomic, strong) NSArray *imageURLs;
@property (nonatomic, strong) NSMutableDictionary *runningDownloadOperationsKeyedByURL;

@end

@implementation FTFImage

- (instancetype)initWithImageURLs:(NSArray *)imageURLs;
{
    self = [super init];
    if(self) {
        _imageURLs = imageURLs;
        _runningDownloadOperationsKeyedByURL = [NSMutableDictionary new];
    }
    return self;
}

- (NSURL *)largePhotoURL {
    if (self.imageURLs.count <= FTFImageSizeLarge) {
        return nil;
    }
    
    return self.imageURLs[FTFImageSizeLarge];
}

- (NSURL *)smallPhotoURL {
    if (self.imageURLs.count < FTFImageSizeSmall) {
        return nil;
    }
    
    return self.imageURLs[FTFImageSizeSmall];
}

- (NSURL *)imageURLWithSize:(FTFImageSize)size;
{
    if (FTFImageSizeLarge == size) {
        return self.largePhotoURL;
    }
    
    return self.smallPhotoURL;
}

- (void)cancel;
{
    [self.runningDownloadOperationsKeyedByURL enumerateKeysAndObjectsUsingBlock:^(id key, id<SDWebImageOperation> operation, BOOL *stop) {
        [operation cancel];
    }];
}

- (void)requestImageWithSize:(FTFImageSize)size completionBlock:(void(^)(UIImage *image, NSError *error, BOOL isCached))block;
{
    NSParameterAssert(block);
    
    block = ^(UIImage *image, NSError *error, BOOL isCached) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(image, error, isCached);
        });
    };
    
    NSURL *URL = [self imageURLWithSize:size];
    if (!URL) {
        block(nil, nil, NO);
        return;
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        UIImage *cachedImage = [manager.imageCache imageFromDiskCacheForKey:URL.absoluteString];
        if (cachedImage) {
            block(cachedImage, nil, YES);
            return;
        }
    
        SDWebImageOptions options = SDWebImageRetryFailed;
        self.runningDownloadOperationsKeyedByURL[URL] = [manager downloadWithURL:URL options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (finished) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [manager saveImageToCache:image forURL:URL];
                    [self.runningDownloadOperationsKeyedByURL removeObjectForKey:URL];
                    block(image, error, NO);
                });
            }
        }];
    });
}

- (void)addPhotoComment:(FTFPhotoComment *)photoComment {
    NSMutableArray *mutableArray = [self.photoComments mutableCopy];
    [mutableArray addObject:photoComment];
    self.photoComments = [mutableArray copy];
}

@end

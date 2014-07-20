//
//  FTFImage.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFImage.h"
#import "SDWebImageManager.h"

@interface FTFImage()

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

- (NSURL *)imageURLWithSize:(FTFImageSize)size;
{
    if(size >= self.imageURLs.count) {
        return nil;
    }
    
    return self.imageURLs[size];
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
    
    NSURL *URL = [self imageURLWithSize:size];
    if (!URL) {
        block(nil, nil, NO);
        return;
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    UIImage *cachedImage = [manager.imageCache imageFromMemoryCacheForKey:URL.absoluteString];
    if (cachedImage) {
        block(cachedImage, nil, YES);
        return;
    }
    
    self.runningDownloadOperationsKeyedByURL[URL] = [manager downloadWithURL:URL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        if (finished && URL) {
            [manager saveImageToCache:image forURL:URL];
        }
        
        block(image, error, NO);
    }];
}

- (NSArray *)imageURLs {
    return _imageURLs;
}

- (NSURL *)largePhotoURL {
    return self.imageURLs[FTFImageSizeLarge];
}

@end

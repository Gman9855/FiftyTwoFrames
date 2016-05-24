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
#import "FTFPhotoComment.h"

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

+ (NSArray *)photosWithPhotoResponse:(NSDictionary *)dict {
    NSArray *photoCollections;
    NSArray *photoDescriptionCollection;
    NSArray *likesCountCollection;
    NSArray *commentsCollection;
    NSArray *userHasLikedPhotoCollection;
    NSArray *photoIDs = [dict valueForKeyPath:@"id"];
    if ([photoIDs isKindOfClass:[NSString class]]) {
        photoIDs = @[[dict valueForKeyPath:@"id"]];
        photoCollections = @[[dict valueForKeyPath:@"images"]];
        photoDescriptionCollection = @[[dict valueForKeyPath:@"name"]];
        likesCountCollection = @[[dict valueForKeyPath:@"likes.summary.total_count"]];
        if ([dict valueForKeyPath:@"comments.data"]) {
            commentsCollection = @[[dict valueForKeyPath:@"comments.data"]];
        }
        userHasLikedPhotoCollection = @[[dict valueForKeyPath:@"likes.summary.has_liked"]];
    } else {
        photoCollections = [dict valueForKeyPath:@"images"];
        photoDescriptionCollection = [dict valueForKeyPath:@"name"];
        likesCountCollection = [dict valueForKeyPath:@"likes.summary.total_count"];
        commentsCollection = [dict valueForKeyPath:@"comments.data"];
        userHasLikedPhotoCollection = [dict valueForKeyPath:@"likes.summary.has_liked"];
    }
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [photoCollections count]; i++) {
        NSArray *array = photoCollections[i];
        NSDictionary *largePhotoDict = array.firstObject;
        
        NSDictionary *smallPhotoDict = [self preferredSmallPhotoURLDictFromPhotoArray:photoCollections[i]];
        
        //        NSArray *imageURLs = [self urlsFromPhotoArray:photoCollections[i]];
        NSString *largePhotoStringURL = [largePhotoDict valueForKey:@"source"];
        NSString *smallPhotoStringURL = [smallPhotoDict valueForKey:@"source"];
        
        NSURL *largePhotoURL = [NSURL URLWithString:largePhotoStringURL];
        NSURL *smallPhotoURL = [NSURL URLWithString:smallPhotoStringURL];
        
        FTFImage *image = [[FTFImage alloc] initWithImageURLs:@[largePhotoURL, smallPhotoURL]];
        
        CGFloat smallPhotoWidth = [[smallPhotoDict valueForKey:@"width"] floatValue];
        CGFloat smallPhotoHeight = [[smallPhotoDict valueForKey:@"height"] floatValue];
        
        CGFloat largePhotoWidth = [[largePhotoDict valueForKey:@"width"] floatValue];
        CGFloat largePhotoHeight = [[largePhotoDict valueForKey:@"height"] floatValue];
        
        image.smallPhotoSize = CGSizeMake(smallPhotoWidth, smallPhotoHeight);
        image.largePhotoSize = CGSizeMake(largePhotoWidth, largePhotoHeight);
        
        BOOL containsPhotoDescription = ![photoDescriptionCollection[i] isEqual:[NSNull null]];
        NSString *photoTitle;
        if (containsPhotoDescription) {
            NSArray *lines = [photoDescriptionCollection[i] componentsSeparatedByString:@"\n"];
            for (NSString *string in lines) {
                if (string.length > 0) {                //the string starting with a " is the title of the photo
                    NSString *firstLetter = [string substringToIndex:1];
                    if ([firstLetter isEqualToString:@"\""]) {
                        photoTitle = string;
                        break;
                    }
                }
            }
            
            image.title = photoTitle.length > 0 ? [[photoTitle stringByReplacingOccurrencesOfString:@"\"" withString:@""] capitalizedString] : [lines[0] capitalizedString];
            image.photographerName = [lines[0] capitalizedString];
            image.photoDescription = photoDescriptionCollection[i];
        }
        
        image.likesCount = [likesCountCollection[i]integerValue];
        image.photoID = photoIDs[i];
        
        image.isLiked = [userHasLikedPhotoCollection[i] intValue];
        NSArray *photoComments = commentsCollection[i];
        NSMutableArray *arrayOfphotoCommentObjects = [NSMutableArray new];
        if (photoComments != (id)[NSNull null]) {
            for (NSDictionary *comment in photoComments) {
                FTFPhotoComment *photoComment = [FTFPhotoComment new];
                photoComment.commenterName = [comment valueForKeyPath:@"from.name"];
                photoComment.commenterID = [comment valueForKeyPath:@"from.id"];
                NSString *commentDate = [comment valueForKey:@"created_time"];
                photoComment.createdTime = [self formattedDateStringFromFacebookDate:commentDate];
                photoComment.likeCount = [comment valueForKey:@"like_count"];
                photoComment.comment = [comment valueForKey:@"message"];
                photoComment.commenterProfilePictureURL = [NSURL URLWithString:[comment valueForKeyPath:@"from.picture.data.url"]];
                [arrayOfphotoCommentObjects addObject:photoComment];
            }
            NSSortDescriptor *createdTimeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdTime" ascending:YES];
            image.comments = [[arrayOfphotoCommentObjects sortedArrayUsingDescriptors:@[createdTimeSortDescriptor]] copy];
        }
        [objects addObject:image];
    }
    return objects;
}

- (void)addPhotoComment:(FTFPhotoComment *)photoComment {
    NSMutableArray *mutableArray;
    if (self.comments != nil) {
        mutableArray = [self.comments mutableCopy];
    } else {
        mutableArray = [NSMutableArray new];
    }
    
    [mutableArray addObject:photoComment];
    self.comments = [mutableArray copy];
}

#pragma mark - Helper Methods

+ (NSDate *)formattedDateStringFromFacebookDate:(NSString *)fbDate {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
    });
    
    return [dateFormatter dateFromString:fbDate];
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

+ (NSDictionary *)preferredSmallPhotoURLDictFromPhotoArray:(NSArray *)array {
    NSDictionary *smallImageDict = [array firstObject];
    for (NSDictionary *dict in array) {
        NSInteger imageHeight = [[dict valueForKeyPath:@"height"]intValue];
        if (imageHeight <= 500 && imageHeight >= 350) {
            smallImageDict = dict;
            break;
        }
    }
    
    return smallImageDict;
}

- (NSString *)sourceOfImageData:(NSDictionary *)data {
    return [data valueForKeyPath:@"source"];
}



@end

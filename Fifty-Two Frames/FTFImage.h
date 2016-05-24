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

typedef enum {
    FTFImageCritiqueTypeRegular,
    FTFImageCritiqueTypeShredAway,
    FTFImageCritiqueTypeExtraSensitive,
    FTFImageCritiqueTypeNotInterested
} FTFImageCritiqueType;

@interface FTFImage : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *photographerName;
@property (nonatomic, strong) NSString *photoDescription;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) NSString *photoID;
@property (nonatomic, assign) double aperture;
@property (nonatomic, strong) NSString *apertureString;
@property (nonatomic, assign) double shutterSpeed;
@property (nonatomic, strong) NSString *shutterSpeedString;
@property (nonatomic, assign) NSInteger focalLength;
@property (nonatomic, strong) NSString *focalLengthString;
@property (nonatomic, assign) NSInteger ISO;
@property (nonatomic, strong) NSString *isoString;
@property (nonatomic, assign) FTFImageCritiqueType critiqueType;
@property (nonatomic, strong, readonly) NSURL *smallPhotoURL;
@property (nonatomic, strong, readonly) NSURL *largePhotoURL;
@property (nonatomic, assign) CGSize smallPhotoSize;
@property (nonatomic, assign) CGSize largePhotoSize;

@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, assign) BOOL qualifiesForExtraCreditChallenge;
@property (nonatomic, assign) BOOL fromNewFramer;

- (instancetype)initWithImageURLs:(NSArray *)imageURLs;
- (void)requestImageWithSize:(FTFImageSize)size completionBlock:(void(^)(UIImage *image, NSError *error, BOOL isCached))block;
- (void)cancel;
- (NSArray *)imageURLs;

- (void)addPhotoComment:(FTFPhotoComment *)photoComment;


@end

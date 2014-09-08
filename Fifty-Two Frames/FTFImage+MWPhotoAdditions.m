//
//  FTFImage+MWPhotoAdditions.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/31/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFImage+MWPhotoAdditions.h"

@implementation FTFImage (MWPhotoAdditions)

- (MWPhoto *)browserPhotoWithSize:(FTFImageSize)size {
    NSArray *largeAndSmallURLs = @[self.largePhotoURL, self.smallPhotoURL];
    MWPhoto *photo = [MWPhoto photoWithURL:largeAndSmallURLs[size]];
    if (![self.photoDescription isEqual:[NSNull null]]) {
        photo.caption = self.photoDescription;
    }
    return photo;
}

@end

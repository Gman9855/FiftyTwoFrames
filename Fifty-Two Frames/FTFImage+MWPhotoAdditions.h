//
//  FTFImage+MWPhotoAdditions.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/31/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFImage.h"
#import "MWPhoto.h"

@interface FTFImage (MWPhotoAdditions)

- (MWPhoto *)browserPhotoWithSize:(FTFImageSize)size;

@end

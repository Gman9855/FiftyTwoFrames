//
//  FTFAlbum.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FTFImage;

@interface FTFAlbum : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *albumID;
@property (nonatomic, strong) NSString *info;
@property (nonatomic, strong) NSString *yearCreated;
@property (nonatomic, strong) NSURL *coverPhotoURL;
@property (nonatomic, strong) NSArray<FTFImage *> *photos;

//- (void)retrieveAlbumPhotos:(void(^)(NSArray *photos, NSError *error))block;
 // of FTFImage's

@end

//
//  FTFAlbum.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 7/24/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFAlbum.h"
#import "FTFImage.h"
#import "FTFPhotoComment.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FTFAlbum ()

@end

@implementation FTFAlbum

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {
        // Decode the property values by key, and assign them to the correct ivars
        _name = [coder decodeObjectForKey:@"name"];
        _albumID = [coder decodeObjectForKey:@"albumID"];
        _info = [coder decodeObjectForKey:@"info"];
        _yearCreated = [coder decodeObjectForKey:@"yearCreated"];
        _coverPhotoURL = [coder decodeObjectForKey:@"coverPhotoURL"];
        _photos = [coder decodeObjectForKey:@"photos"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    // Encode our ivars using string keys
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_albumID forKey:@"albumID"];
    [coder encodeObject:_info forKey:@"info"];
    [coder encodeObject:_yearCreated forKey:@"yearCreated"];
    [coder encodeObject:_coverPhotoURL forKey:@"coverPhotoURL"];
    [coder encodeObject:_photos forKey:@"photos"];
}

@end

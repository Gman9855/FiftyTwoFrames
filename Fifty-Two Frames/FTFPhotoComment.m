//
//  FTFPhotoComment.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoComment.h"
#import "FiftyTwoFrames.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface FTFPhotoComment()

@end

@implementation FTFPhotoComment

- (NSString *)description {
    return [NSString stringWithFormat:@"Comment: %@, Commenter name: %@", self.comment, self.commenterName];
}

- (void)setCommenterID:(id)commenterID {
    _commenterID = commenterID;
}

@end
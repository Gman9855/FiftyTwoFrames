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

- (NSURL *)commenterProfilePictureURL {
    if (!_commenterProfilePictureURL) {
        _commenterProfilePictureURL = [NSURL new];
    }
    return _commenterProfilePictureURL;
}

- (void)setCommenterID:(id)commenterID {
    _commenterID = commenterID;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"false", @"redirect",
                            @"200", @"height",
                            @"normal", @"type",
                            @"200", @"width",
                            nil
                            ];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/picture?redirect=false", _commenterID] parameters:params HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (result) {
            self.commenterProfilePictureURL = [[NSURL alloc] initWithString:[result valueForKeyPath:@"data.url"]];
        }
    }];
}

@end

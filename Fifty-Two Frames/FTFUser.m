//
//  FTFUser.m
//  FiftyTwoFrames
//
//  Created by Gershon Lev on 9/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFUser.h"

@implementation FTFUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        _name = [dict valueForKey:@"name"];
        _userID = [dict valueForKey:@"id"];
        _profilePictureURL = [NSURL URLWithString:[dict valueForKeyPath:@"picture.data.url"]];
    }
    
    return self;
}

@end

//
//  FTFUser.h
//  FiftyTwoFrames
//
//  Created by Gershon Lev on 9/13/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTFUser : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSURL *profilePictureURL;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

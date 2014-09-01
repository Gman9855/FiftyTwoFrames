//
//  FTFPhotoComment.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 8/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTFPhotoComment : NSObject

@property (nonatomic, strong) NSString *commenterName;
@property (nonatomic, strong) id commenterID;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSString *comment;


- (void)requestCommenterProfilePictureWithCompletionBlock:(void(^)(UIImage *image, NSError *error))block;

@end

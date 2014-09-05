//
//  FTFPhotoCommentsViewController.h
//  
//
//  Created by Gershy Lev on 8/7/14.
//
//

#import <UIKit/UIKit.h>

@protocol FTFPhotoCommentsViewControllerDelegate <NSObject>

- (void)photoCommentsViewControllerDidTapDoneButton;

@end

@interface FTFPhotoCommentsViewController : UIViewController

@property (nonatomic, weak) id <FTFPhotoCommentsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *photoComments;

@end

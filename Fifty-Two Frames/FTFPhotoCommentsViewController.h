//
//  FTFPhotoCommentsViewController.h
//  
//
//  Created by Gershy Lev on 8/7/14.
//
//

#import <UIKit/UIKit.h>

@class FTFImage;

@protocol FTFPhotoCommentsViewControllerDelegate <NSObject>

- (void)photoCommentsViewControllerDidTapDoneButton;

@end

@interface FTFPhotoCommentsViewController : UIViewController

@property (weak, nonatomic, readonly) IBOutlet UITableView *tableView;

@property (nonatomic, weak) id <FTFPhotoCommentsViewControllerDelegate> delegate;
@property (nonatomic, strong) FTFImage *photo;

@end

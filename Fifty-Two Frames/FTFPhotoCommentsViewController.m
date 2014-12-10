//
//  FTFPhotoCommentsViewController.m
//  
//
//  Created by Gershy Lev on 8/7/14.
//
//

#import "FTFPhotoCommentsViewController.h"
#import "FTFPhotoCommentTableViewCell.h"
#import "FTFPhotoComment.h"
#import "FTFUser.h"
#import "UIImageView+WebCache.h"
#import "TTTTimeIntervalFormatter.h"

#import "FiftyTwoFrames.h"

@interface FTFPhotoCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewBottomConstraint;

@property (weak, nonatomic, readwrite) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *postCommentButton;
@property (nonatomic, assign) NSInteger keyboardHeight;

@end

static NSString * const reuseIdentifier = @"commentCell";

@implementation FTFPhotoCommentsViewController {
    BOOL shouldIgnoreKeyboardEvents;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 59;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.textField.delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:(arc4random() % 6) + 6
                                     target:self
                                   selector:@selector(updateVisibleCells:)
                                   userInfo:nil
                                    repeats:YES];
}


- (CGRect)convertedRectFromKeyboardNotification:(NSNotification *)notification;
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    return [self.view convertRect:keyboardRect fromView:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!shouldIgnoreKeyboardEvents) {
        CGSize keyboardSize = [self convertedRectFromKeyboardNotification:notification].size;
        
        //Given size may not account for screen rotation
        self.keyboardHeight = MIN(keyboardSize.height,keyboardSize.width);
     
        [self animateUsingKeyboardUserInfo:notification.userInfo animations:^{
            [self updateInputView];
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    if (!shouldIgnoreKeyboardEvents) {
        self.keyboardHeight = 0;
        
        [self animateUsingKeyboardUserInfo:notification.userInfo animations:^{
            [self updateInputView];
        }];
    }
}

- (void)animateUsingKeyboardUserInfo:(NSDictionary *)userInfo animations:(dispatch_block_t)animations;
{
    BOOL showingLastIndexPath = [[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:self.photo.photoComments.count - 1]];
    
    [UIView beginAnimations:nil context:NULL];
    
    if (!showingLastIndexPath) {
        [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    }
    
    animations();
    
    [UIView commitAnimations];
}

#pragma mark - Text Field Delegate

- (void)updateInputView;
{
    self.inputViewBottomConstraint.constant = self.keyboardHeight;

    if (self.keyboardHeight) {
        [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, CGFLOAT_MAX) animated:NO];
    }
}

#pragma mark - Actions

- (IBAction)doneButtonTapped:(UIBarButtonItem *)sender {
    if ([self.textField isFirstResponder]) {
        [self.view endEditing:YES];
    } else {
        [self.delegate photoCommentsViewControllerDidTapDoneButton];
    }
}

- (IBAction)postButtonTapped:(UIButton *)sender {
    FTFUser *user = [FiftyTwoFrames sharedInstance].user;
    FTFPhotoComment *postedComment = [[FTFPhotoComment alloc] init];
    postedComment.commenterName = user.name;
    postedComment.commenterID = user.userID;
    postedComment.commenterProfilePictureURL = user.profilePictureURL;
    postedComment.createdTime = [NSDate date];
    shouldIgnoreKeyboardEvents = YES;
    [self.textField resignFirstResponder];
    [self.textField becomeFirstResponder];
    shouldIgnoreKeyboardEvents = NO;
    postedComment.comment = self.textField.text;
    
//    [[FiftyTwoFrames sharedInstance] publishPhotoCommentWithPhotoID:self.photo.photoID
//                                                            comment:postedComment.comment
//                                                    completionBlock:^(NSError *error) {
//        if (error) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                            message:@"Something went wrong trying to post your comment"
//                                                           delegate:self
//                                                  cancelButtonTitle:@"Okay"
//                                                  otherButtonTitles:nil];
//            [alert show];
//            return;
//        }
//    }];
    
    [self.tableView beginUpdates];
    [self.photo addPhotoComment:postedComment];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.photo.photoComments.count - 1];
    [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];

    [self.tableView endUpdates];
    
    NSIndexPath *idx = [NSIndexPath indexPathForRow:0 inSection:self.photo.photoComments.count - 1];
    [self.tableView scrollToRowAtIndexPath:idx atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    self.textField.text = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photo.photoComments count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FTFPhotoCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                                              forIndexPath:indexPath];
    FTFPhotoComment *photoComment = self.photo.photoComments[indexPath.row];
    
    [cell.commenterProfilePicture setImageWithURL:photoComment.commenterProfilePictureURL];
    
    cell.commenterName.text = photoComment.commenterName;
    cell.commentBody.text = photoComment.comment;
    
    cell.commentDate.text = [self timeIntervalformattedDateStringFromFacebookDate:photoComment.createdTime];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"commentCell"];
    CGFloat height = cell.bounds.size.height;
    
    return height + 10;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self configureCommentCell:(FTFPhotoCommentTableViewCell *)cell atIndexPath:indexPath];
//}
//
//- (FTFPhotoCommentTableViewCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath {
//    FTFPhotoCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier
//                                                                              forIndexPath:indexPath];
//    [self configureCommentCell:cell atIndexPath:indexPath];
//    return cell;
//}

- (void)configureCommentCell:(FTFPhotoCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
//    FTFPhotoComment *photoComment = self.photo.photoComments[indexPath.section];
//    
//    [cell.commenterProfilePicture setImageWithURL:photoComment.commenterProfilePictureURL];
//    
//    cell.commenterName.text = photoComment.commenterName;
//    cell.commentBody.text = photoComment.comment;
//    
//    cell.commentDate.text = [self timeIntervalformattedDateStringFromFacebookDate:photoComment.createdTime];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return [self heightForCommentCellAtIndexPath:indexPath];
//}
//
//- (CGFloat)heightForCommentCellAtIndexPath:(NSIndexPath *)indexPath {
//    static FTFPhotoCommentTableViewCell *sizingCell = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
//    });
//    
//    [self configureCommentCell:sizingCell atIndexPath:indexPath];
//    return [self calculateHeightForConfiguredSizingCell:sizingCell];
//}
//
//- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
//    [sizingCell setNeedsLayout];
//    [sizingCell layoutIfNeeded];
//    
//    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//    return size.height;
//}

#pragma mark - Helper methods

- (NSString *)timeIntervalformattedDateStringFromFacebookDate:(NSDate *)date {
    
    static TTTTimeIntervalFormatter *intervalFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        intervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
    });
    return [intervalFormatter stringForTimeInterval:[date timeIntervalSinceDate:[NSDate date]]];
}

- (void)updateVisibleCells:(NSTimer *)timer {
    //[self.tableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

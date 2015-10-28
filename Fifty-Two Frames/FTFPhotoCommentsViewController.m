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

static NSAttributedString *bluePostString = nil;
static NSAttributedString *lightGrayPostString = nil;

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
    
    self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.postCommentButton.enabled = NO;
    self.tableView.estimatedRowHeight = 75;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self.textField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardFrameDidChange:)
//                                                 name:UIKeyboardDidChangeFrameNotification object:nil];

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
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.inputViewBottomConstraint.constant = keyboardFrame.size.height;
    } completion:^(BOOL finished) {
        if (finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.photo.comments.count - 1 inSection:0]atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            });
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    [UIView animateWithDuration:0.1 animations:^{
        self.inputViewBottomConstraint.constant = 0;
    }];
}

#pragma mark - Text Field Delegate

- (void)textFieldDidChange:(NSNotification *)notification {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bluePostString = [[NSAttributedString alloc]initWithString:self.postCommentButton.titleLabel.text attributes:@{NSForegroundColorAttributeName : self.postCommentButton.tintColor}];
        lightGrayPostString = [[NSAttributedString alloc]initWithString:self.postCommentButton.titleLabel.text attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    });
    
    BOOL textFieldHasText = (![self.textField.text isEqualToString:@""]);
    [self setPostButtonColorWithEnabledState:textFieldHasText];
    
}

#pragma mark - Actions

- (IBAction)doneButtonTapped:(UIBarButtonItem *)sender {
    if ([self.textField isFirstResponder]) {
        [self.view endEditing:YES];
    } else {
        [self dismissViewControllerAnimated:true completion:nil];
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
//    [self.textField resignFirstResponder];
//    [self.textField becomeFirstResponder];
    shouldIgnoreKeyboardEvents = NO;
    postedComment.comment = self.textField.text;
    
    [[FiftyTwoFrames sharedInstance] publishPhotoCommentWithPhotoID:self.photo.photoID
                                                            comment:postedComment.comment
                                                    completionBlock:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Could not post your comment.  Please check your internet."
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }];
    
    [self.photo addPhotoComment:postedComment];
    [self.tableView beginUpdates];
    
    NSIndexPath *i = [NSIndexPath indexPathForRow:self.photo.comments.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[i] withRowAnimation:UITableViewRowAnimationBottom];
    
    [self.tableView endUpdates];
    
    BOOL isAtBottom = (self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.frame.size.height));
    NSLog(@"Is at bottom: %s", isAtBottom ? "Yes" : "No");
    NSIndexPath *secondToLastCellIndex = [NSIndexPath indexPathForRow:self.photo.comments.count - 2 inSection:0];
    FTFPhotoCommentTableViewCell *commentCell = [self.tableView cellForRowAtIndexPath:secondToLastCellIndex];
    NSArray *visibleCells = [self.tableView visibleCells];
    NSIndexPath *lastCellIndex = [NSIndexPath indexPathForRow:self.photo.comments.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastCellIndex atScrollPosition:UITableViewScrollPositionBottom animated: [visibleCells containsObject:commentCell] ? NO : YES];
    
    self.textField.text = nil;
    [self setPostButtonColorWithEnabledState:NO];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photo.comments count];
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
    FTFPhotoComment *photoComment = self.photo.comments[indexPath.row];
    
    [cell.commenterProfilePicture setImageWithURL:photoComment.commenterProfilePictureURL];
    
    cell.commenterName.text = photoComment.commenterName;
    cell.commentBody.text = photoComment.comment;
    
    cell.commentDate.text = [self timeIntervalformattedDateStringFromFacebookDate:photoComment.createdTime];
    return cell;
}

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
    [self.tableView reloadData];
}

- (void)setPostButtonColorWithEnabledState:(BOOL)enabled {
    [self.postCommentButton setAttributedTitle:enabled ? bluePostString : lightGrayPostString forState:UIControlStateNormal];
    self.postCommentButton.enabled = enabled;
}

@end

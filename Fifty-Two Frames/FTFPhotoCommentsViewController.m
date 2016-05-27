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
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "MBProgressHUD.h"

static NSAttributedString *bluePostString = nil;
static NSAttributedString *lightGrayPostString = nil;

@interface FTFPhotoCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewToSendButtonSpacingConstraint;

@property (weak, nonatomic, readwrite) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *postCommentButton;
@property (nonatomic, assign) NSInteger keyboardHeight;
@property (weak, nonatomic) IBOutlet UIView *textViewContainingView;

@end

static NSString * const reuseIdentifier = @"commentCell";

@implementation FTFPhotoCommentsViewController {
    BOOL shouldIgnoreKeyboardEvents;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textViewContainingView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textViewContainingView.layer.borderWidth = 0.5;
    self.postCommentButton.enabled = NO;
    self.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.textView.layer.borderWidth = 0.5;
    self.textView.text = @"Say something about the photo...";
    self.textView.textColor = [UIColor lightGrayColor];
    self.tableView.estimatedRowHeight = 75;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.textView.delegate = self;
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
                if (self.photo.comments.count > 0) {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.photo.comments.count - 1 inSection:0]atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
                
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

#pragma mark - Text View Delegate

- (void)textViewDidChange:(UITextView *)textView {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bluePostString = [[NSAttributedString alloc]initWithString:self.postCommentButton.titleLabel.text attributes:@{NSForegroundColorAttributeName : self.postCommentButton.tintColor}];
        lightGrayPostString = [[NSAttributedString alloc]initWithString:self.postCommentButton.titleLabel.text attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    });
    
    BOOL textFieldHasText = (![self.textView.text isEqualToString:@""]);
    [self setPostButtonColorWithEnabledState:textFieldHasText];
    
    self.postCommentButton.enabled = [self.textView.text length] > 0;
    
    CGSize textViewSize = [textView sizeThatFits:CGSizeMake(textView.bounds.size.width, FLT_MAX)];
    self.textViewHeightConstraint.constant = textViewSize.height;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.location == 0 && [text isEqualToString:@" "]) {
        return NO;
    }
    return YES;
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"Say something about the photo..."]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Say something about the photo...";
        textView.textColor = [UIColor lightGrayColor];
    }
}

#pragma mark - Actions

- (IBAction)doneButtonTapped:(UIBarButtonItem *)sender {
    if ([self.textView isFirstResponder]) {
        [self.view endEditing:YES];
    }
    [self dismissViewControllerAnimated:true completion:nil];

}

- (IBAction)postButtonTapped:(UIButton *)sender {
    BOOL hasTappedPostButtonOnce = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasTappedPostButtonOnce"];
    if (!hasTappedPostButtonOnce) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"This will post a comment on this photo to Facebook.  Do you wish to continue?" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTappedPostButtonOnce"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self postComment];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
    } else {
        
        [self postComment];
    }
}

- (IBAction)tapReceivedInTableView:(UITapGestureRecognizer *)sender {
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
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

#pragma mark

- (void)postComment {
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        [self setPostButtonColorWithEnabledState:NO];
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
        postedComment.comment = self.textView.text;
        [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        [[FiftyTwoFrames sharedInstance] publishPhotoCommentWithPhotoID:self.photo.photoID
                                                                comment:postedComment.comment
                                                        completionBlock:^(NSError *error) {
                                                            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setPostButtonColorWithEnabledState:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"We tried!  Looks like your internet is down.  Please try again."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Okay"
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                    return;
                });
                
            } else {
                [self.photo addPhotoComment:postedComment];
                dispatch_async(dispatch_get_main_queue(), ^{
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
                    
                    self.textView.text = nil;
                    [self setPostButtonColorWithEnabledState:NO];
                });
                
            }
        }];

    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"In order to like or comment on a photo, you'll need to grant this app permission to post to Facebook. We will NEVER submit anything without your permission. Do you wish to continue?" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
            [loginManager logInWithPublishPermissions:@[@"publish_actions"]
                                   fromViewController:self
                                              handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                                  if (error) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Something went wrong.  Please check your internet and try again." preferredStyle:UIAlertControllerStyleAlert];
                                                          UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                                                          [alertController addAction:okAction];
                                                          [self presentViewController:alertController animated:YES completion:nil];
                                                      });
                                                  }
                                              }];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
    }
}

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

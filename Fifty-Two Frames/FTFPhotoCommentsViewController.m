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

@interface FTFPhotoCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

static NSString * const reuseIdentifier = @"commentCell";

@implementation FTFPhotoCommentsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.textField.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
    NSInteger lastRow = [self.photoComments count] - 1;
    NSIndexPath *ip = [NSIndexPath indexPathWithIndex:lastRow];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 205;
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    }];
}

#pragma mark - Actions

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    if ([self.textField isFirstResponder]) {
        [self.view endEditing:YES];
    } else {
        [self.delegate dismissPhotoCommentsViewController];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.photoComments count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
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
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCommentCell:(FTFPhotoCommentTableViewCell *)cell atIndexPath:indexPath];
}

- (FTFPhotoCommentTableViewCell *)commentCellAtIndexPath:(NSIndexPath *)indexPath {
    FTFPhotoCommentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                                              forIndexPath:indexPath];
    [self configureCommentCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCommentCell:(FTFPhotoCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    FTFPhotoComment *photoComment = self.photoComments[indexPath.section];
    [photoComment requestCommenterProfilePictureWithCompletionBlock:^(UIImage *image, NSError *error) {
        if (image) cell.commenterProfilePicture.image = image;
    }];
    cell.commenterName.text = photoComment.commenterName;
    cell.commentBody.text = photoComment.comment;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    NSString *strDate = [dateFormatter stringFromDate:photoComment.createdTime];
    cell.commentDate.text = strDate;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForCommentCellAtIndexPath:indexPath];
}

- (CGFloat)heightForCommentCellAtIndexPath:(NSIndexPath *)indexPath {
    static FTFPhotoCommentTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    });
    
    [self configureCommentCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
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

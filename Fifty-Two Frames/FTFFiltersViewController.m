//
//  FTFFiltersViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/13/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFFiltersViewController.h"

@interface FTFFiltersViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sortByLikesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sortByCommentsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sortByNamesSwitch;

@end

@implementation FTFFiltersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchTextField.delegate = self;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReceivedInView:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sortByLikesSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.sortByNamesSwitch setOn:NO animated:true];
        [self.sortByCommentsSwitch setOn:NO animated:true];
    }
}

- (IBAction)sortByCommentsSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.sortByNamesSwitch setOn:NO animated:true];
        [self.sortByLikesSwitch setOn:NO animated:true];
    }
}

- (IBAction)sortByNameSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.sortByLikesSwitch setOn:NO animated:true];
        [self.sortByCommentsSwitch setOn:NO animated:true];
    }
}

- (void)tapReceivedInView:(UITapGestureRecognizer *)sender {
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }
}

- (IBAction)saveButtonTapped:(UIButton *)sender {
    if (![self shouldSaveFilters]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops!" message:@"Looks like you missed something." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:alertAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    FTFSortOrder sortOrder = FTFSortOrderNone;
    if (self.sortByLikesSwitch.isOn) {
        sortOrder = FTFSortOrderLikes;
    }
    if (self.sortByNamesSwitch.isOn) {
        sortOrder = FTFSortOrderName;
    }
    if (self.sortByCommentsSwitch.isOn) {
        sortOrder = FTFSortOrderComments;
    }
    
    [self.delegate filtersViewControllerDidSaveFilters:![self.searchTextField.text isEqualToString:@""] ? self.searchTextField.text : nil
                                             sortOrder:sortOrder];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)resetButtonTapped:(UIBarButtonItem *)sender {
    [self.sortByLikesSwitch setOn:NO];
    [self.sortByNamesSwitch setOn:NO];
    [self.sortByCommentsSwitch setOn:NO];
    self.searchTextField.text = @"";
    
    [self.delegate filtersViewControllerDidResetFilters];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldSaveFilters {
    return self.sortByNamesSwitch.isOn || self.sortByLikesSwitch.isOn || self.sortByCommentsSwitch.isOn || ![self.searchTextField.text isEqualToString:@""];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.location == 0 && [string isEqualToString:@" "]) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

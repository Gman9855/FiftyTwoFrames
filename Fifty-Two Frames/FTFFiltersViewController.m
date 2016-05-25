//
//  FTFFiltersViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 5/13/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import "FTFFiltersViewController.h"
#import "NMRangeSlider.h"
#import "FTFApertureRangeSlider.h"
#import "FTFFocalLengthRangeSlider.h"
#import "FTFShutterSpeedRangeSlider.h"
#import "FTFISORangeSlider.h"

@interface FTFFiltersViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sortByLikesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sortByCommentsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *apertureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *focalLengthSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shutterSpeedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *extraCreditChallengeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *ISOSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *framerNewSwitch;
@property (weak, nonatomic) IBOutlet UILabel *apertureValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *shutterSpeedValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *focalLengthValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *ISOValueLabel;
@property (weak, nonatomic) IBOutlet FTFApertureRangeSlider *apertureRangeSlider;
@property (weak, nonatomic) IBOutlet FTFFocalLengthRangeSlider *focalLengthRangeSlider;
@property (weak, nonatomic) IBOutlet FTFShutterSpeedRangeSlider *shutterSpeedRangeSlider;
@property (weak, nonatomic) IBOutlet FTFISORangeSlider *ISORangeSlider;

@end

@implementation FTFFiltersViewController

- (NSArray *)switches {
    return @[self.sortByLikesSwitch, self.sortByCommentsSwitch, self.apertureSwitch, self.focalLengthSwitch, self.shutterSpeedSwitch, self.extraCreditChallengeSwitch, self.framerNewSwitch];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchTextField.delegate = self;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReceivedInView:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (IBAction)sortByLikesSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.sortByCommentsSwitch setOn:NO animated:true];
    }
}

- (IBAction)sortByCommentsSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.sortByLikesSwitch setOn:NO animated:true];
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
    NSNumber *sortOrder = [NSNumber numberWithInt:FTFSortOrderNone];
    NSNumber *newFramers = [NSNumber numberWithBool:NO];
    NSNumber *extraCreditChallenge = [NSNumber numberWithBool:NO];
    NSNumber *apertureLowerValue = [NSNumber numberWithInt:0];
    NSNumber *apertureUpperValue = [NSNumber numberWithInt:0];
    NSNumber *focalLengthLowerValue = [NSNumber numberWithInt:0];
    NSNumber *focalLengthUpperValue = [NSNumber numberWithInt:0];
    NSNumber *shutterSpeedLowerValue = [NSNumber numberWithInt:0];
    NSNumber *shutterSpeedUpperValue = [NSNumber numberWithInt:0];
    NSNumber *ISOLowerValue = [NSNumber numberWithInt:0];
    NSNumber *ISOUpperValue = [NSNumber numberWithInt:0];
    
    if (self.framerNewSwitch.isOn) {
        newFramers = [NSNumber numberWithBool:YES];
    }
    
    if (self.extraCreditChallengeSwitch.isOn) {
        extraCreditChallenge = [NSNumber numberWithBool:YES];
    }
    
    if (self.apertureSwitch.isOn) {
        apertureLowerValue = [NSNumber numberWithDouble:self.apertureRangeSlider.lowerValueAperture];
        apertureUpperValue = [NSNumber numberWithDouble:self.apertureRangeSlider.upperValueAperture];
    }
    
    if (self.focalLengthSwitch.isOn) {
        focalLengthLowerValue = [NSNumber numberWithInt:self.focalLengthRangeSlider.lowerValue];
        focalLengthUpperValue = [NSNumber numberWithInt:self.focalLengthRangeSlider.upperValue];
    }
    
    if (self.shutterSpeedSwitch.isOn) {
        shutterSpeedLowerValue = [NSNumber numberWithDouble:self.shutterSpeedRangeSlider.lowerValueShutterSpeed];
        shutterSpeedUpperValue = [NSNumber numberWithDouble:self.shutterSpeedRangeSlider.upperValueShutterSpeed];
    }
    
    if (self.ISOSwitch.isOn) {
        ISOLowerValue = [NSNumber numberWithInteger:self.ISORangeSlider.lowerValueISO];
        ISOUpperValue = [NSNumber numberWithInteger:self.ISORangeSlider.upperValueISO];
    }
    
    if (self.sortByLikesSwitch.isOn) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderLikes];
    }
    
    if (self.sortByCommentsSwitch.isOn) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderComments];
    }
    
    NSDictionary *filtersDictionary = @{@"searchTerm" : self.searchTextField.text,
                                        @"sortOrder" : sortOrder,
                                        @"newFramers" : newFramers,
                                        @"extraCreditChallenge" : extraCreditChallenge,
                                        @"apertureLowerValue" : apertureLowerValue,
                                        @"apertureUpperValue" : apertureUpperValue,
                                        @"focalLengthLowerValue" : focalLengthLowerValue,
                                        @"focalLengthUpperValue" : focalLengthUpperValue,
                                        @"shutterSpeedLowerValue" : shutterSpeedLowerValue,
                                        @"shutterSpeedUpperValue" : shutterSpeedUpperValue,
                                        @"ISOLowerValue" : ISOLowerValue,
                                        @"ISOUpperValue" : ISOUpperValue
                                        };
    
    [self.delegate filtersViewControllerDidSaveFilters:filtersDictionary];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetButtonTapped:(UIBarButtonItem *)sender {
    [self resetFilters];
    
    [self.delegate filtersViewControllerDidResetFilters];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)apertureRangeSliderValueChanged:(FTFApertureRangeSlider *)sender {
    BOOL sameSliderValues = sender.lowerValue == sender.upperValue;
    self.apertureValueLabel.text = sameSliderValues ? [NSString stringWithFormat:@"%@", sender.upperValueApertureString] : [NSString stringWithFormat:@"%@ - %@", sender.lowerValueApertureString, sender.upperValueApertureString];
}

- (IBAction)focalLengthRangeSliderValueChanged:(FTFFocalLengthRangeSlider *)sender {
    BOOL sameSliderValues = sender.lowerValue == sender.upperValue;
    self.focalLengthValueLabel.text = sameSliderValues ? sender.upperValueFocalLength : [NSString stringWithFormat:@"%@ - %@", sender.lowerValueFocalLength, sender.upperValueFocalLength];
}

- (IBAction)shutterSpeedRangeSliderValueChanged:(FTFShutterSpeedRangeSlider *)sender {
    BOOL sameSliderValues = sender.lowerValue == sender.upperValue;
    self.shutterSpeedValueLabel.text = sameSliderValues ? sender.upperValueShutterSpeedString : [NSString stringWithFormat:@"%@ - %@", sender.lowerValueShutterSpeedString, sender.upperValueShutterSpeedString];
}
- (IBAction)ISORangeSliderValueChanged:(FTFISORangeSlider *)sender {
    BOOL sameSliderValues = sender.lowerValue == sender.upperValue;
    self.ISOValueLabel.text = sameSliderValues ? sender.upperValueISOString : [NSString stringWithFormat:@"%@ - %@", sender.lowerValueISOString, sender.upperValueISOString];
}

- (IBAction)toggleSubmenuCellVisibility:(UISwitch *)sender {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (BOOL)shouldSaveFilters {
    return self.framerNewSwitch.isOn || self.extraCreditChallengeSwitch.isOn || self.apertureSwitch.isOn || self.focalLengthSwitch.isOn || self.shutterSpeedSwitch.isOn || self.ISOSwitch.isOn || self.sortByLikesSwitch.isOn || self.sortByCommentsSwitch.isOn || ![self.searchTextField.text isEqualToString:@""];
}

#pragma mark - UITableViewDelegate 

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 1) {
        if (self.apertureSwitch.on) {
            return 80;
        } else {
            return 0;
        }
    } else if (indexPath.section == 2 && indexPath.row == 3) {
        if (self.focalLengthSwitch.on) {
            return 80;
        } else {
            return 0;
        }
    } else if (indexPath.section == 2 && indexPath.row == 5) {
        if (self.shutterSpeedSwitch.isOn) {
            return 80;
        } else {
            return 0;
        }
    } else if (indexPath.section == 2 && indexPath.row == 7) {
        if (self.ISOSwitch.isOn) {
            return 80;
        } else {
            return 0;
        }
    }
    
    return 44;
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

#pragma mark - Helper Methods

- (void)resetFilters {
    NSArray *switches = [self switches];
    for (UISwitch *sw in switches) {
        if ([sw isOn]) {
            [sw setOn:NO];
            if (sw == self.apertureSwitch || sw == self.focalLengthSwitch || sw == self.shutterSpeedSwitch || sw == self.ISOSwitch) {
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
        }
    }
    
    [self.focalLengthRangeSlider resetKnobs];
    [self.apertureRangeSlider resetKnobs];
    
    self.searchTextField.text = @"";
}

@end

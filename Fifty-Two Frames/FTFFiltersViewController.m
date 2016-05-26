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

typedef enum {
    FTFFilterSectionNameSearch,
    FTFFilterSectionExposure,
    FTFFilterSectionMoreFilters,
    FTFFilterSectionSortBy
} FTFFilterSection;

typedef enum {
    FTFExposureSectionExposureDropdown,
    FTFExposureSectionApertureSwitch,
    FTFExposureSectionApertureSlider,
    FTFExposureSectionShutterSpeedSwitch,
    FTFExposureSectionShutterSpeedSlider,
    FTFExposureSectionISOSwitch,
    FTFExposureSectionISOSlider,
} FTFExposureSection;

typedef enum {
    FTFMoreFiltersSectionFocalLengthSwitch,
    FTFMoreFiltersSectionFocalLengthSlider,
    FTFMoreFiltersSectionNewFramersSwitch,
    FTFMoreFiltersSectionExtraCreditChallengeSwitch
} FTFMoreFiltersSection;

typedef enum {
    FTFSortBySectionDropdown,
    FTFSortBySectionDefault,
    FTFSortBySectionLikes,
    FTFSortBySectionComments
} FTFSortBySection;

@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
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
@property (weak, nonatomic) IBOutlet UIImageView *sortByDefaultCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByLikesCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByCommentsCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByDefaultImageView;
@property (weak, nonatomic) IBOutlet UILabel *sortByLabel;
@property (nonatomic, assign) BOOL exposureDropdownIsSelected;
@property (nonatomic, assign) BOOL sortByDropdownIsSelected;
@property (nonatomic, assign) BOOL sortByDefaultIsSelected;
@property (nonatomic, assign) BOOL sortByLikesIsSelected;
@property (nonatomic, assign) BOOL sortByCommentsIsSelected;

@end

@implementation FTFFiltersViewController

- (NSArray *)switches {
    return @[self.apertureSwitch, self.focalLengthSwitch, self.shutterSpeedSwitch, self.ISOSwitch, self.extraCreditChallengeSwitch, self.framerNewSwitch];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sortByDefaultIsSelected = YES;
    self.searchTextField.delegate = self;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReceivedInView:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
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
    
    if (self.sortByLikesIsSelected) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderLikes];
    } else if (self.sortByCommentsIsSelected) {
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
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }
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
    [self updateSubmenuCellVisibility];
}

#pragma mark - UITableViewDelegate 

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case FTFFilterSectionExposure:
            switch (indexPath.row) {
                case FTFExposureSectionApertureSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExposureSectionApertureSlider:
                    return self.apertureSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                case FTFExposureSectionShutterSpeedSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExposureSectionShutterSpeedSlider:
                    return self.shutterSpeedSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                case FTFExposureSectionISOSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExposureSectionISOSlider:
                    return self.ISOSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                default:
                    break;
            }
            break;
        case FTFFilterSectionMoreFilters:
            switch (indexPath.row) {
                case FTFMoreFiltersSectionFocalLengthSlider:
                    return self.focalLengthSwitch.isOn ? 80 : 0;
                default:
                    break;
            }
            break;
        case FTFFilterSectionSortBy:
            switch (indexPath.row) {
                case FTFSortBySectionDropdown:
                    break;
                default:
                    return !self.sortByDropdownIsSelected ? 0 : 44;
            }
        default:
            break;
    }
    
    return 44;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sortByLabelText = @"Default";
    switch (indexPath.section) {
        case FTFFilterSectionExposure:
            switch (indexPath.row) {
                case FTFExposureSectionExposureDropdown:
                    self.exposureDropdownIsSelected = !self.exposureDropdownIsSelected;
                    [self updateSubmenuCellVisibility];
                    return nil;
                default:
                    break;
            }
            break;
        case FTFFilterSectionSortBy:
            self.sortByDropdownIsSelected = !self.sortByDropdownIsSelected;
            self.sortByDefaultIsSelected = NO;
            self.sortByLikesIsSelected = NO;
            self.sortByCommentsIsSelected = NO;
            switch (indexPath.row) {
                case FTFSortBySectionDropdown:
                    [self updateSubmenuCellVisibility];
                    return nil;
                case FTFSortBySectionDefault:
                    self.sortByDefaultIsSelected = YES;
                    sortByLabelText = @"Default";
                    break;
                case FTFSortBySectionLikes:
                    self.sortByLikesIsSelected = YES;
                    sortByLabelText = @"Likes";
                    break;
                case FTFSortBySectionComments:
                    self.sortByCommentsIsSelected = YES;
                    sortByLabelText = @"Comments";
                    break;
                default:
                    break;
            }
        default:
            break;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.sortByLabel.text = sortByLabelText;
        [self updateSubmenuCellVisibility];
    });
    
    self.sortByCommentsCheckbox.image = [UIImage imageNamed:self.sortByCommentsIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByLikesCheckbox.image = [UIImage imageNamed:self.sortByLikesIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByDefaultCheckbox.image = [UIImage imageNamed:self.sortByDefaultIsSelected ? @"Checked" : @"Unchecked"];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    
    [self.sortByCommentsCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByLikesCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByDefaultCheckbox.layer addAnimation:transition forKey:nil];
    
    return nil;
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
            // Hide subcells
            if (sw == self.apertureSwitch || sw == self.focalLengthSwitch || sw == self.shutterSpeedSwitch || sw == self.ISOSwitch) {
                [self updateSubmenuCellVisibility];
            }
        }
    }
    if (self.sortByDropdownIsSelected) {
        self.sortByDropdownIsSelected = NO;
        [self updateSubmenuCellVisibility];
    }
    
    if (self.exposureDropdownIsSelected) {
        self.exposureDropdownIsSelected = NO;
        [self updateSubmenuCellVisibility];
    }
    
    if (!self.sortByDefaultIsSelected) {
        self.sortByCommentsCheckbox.image = [UIImage imageNamed:@"Unchecked"];
        self.sortByLikesCheckbox.image = [UIImage imageNamed:@"Unchecked"];
        self.sortByDefaultCheckbox.image = [UIImage imageNamed:@"Checked"];
        self.sortByCommentsIsSelected = NO;
        self.sortByLikesIsSelected = NO;
        self.sortByDefaultIsSelected = YES;
        self.sortByLabel.text = @"Default";
    }
    
    [self.focalLengthRangeSlider resetKnobs];
    [self.apertureRangeSlider resetKnobs];
    
    self.searchTextField.text = @"";
}

- (BOOL)shouldSaveFilters {
    return ![self.searchTextField.text isEqualToString:@""] || self.framerNewSwitch.isOn || self.extraCreditChallengeSwitch.isOn || self.apertureSwitch.isOn || self.focalLengthSwitch.isOn || self.shutterSpeedSwitch.isOn || self.ISOSwitch.isOn || self.sortByLikesIsSelected || self.sortByCommentsIsSelected;
}

- (void)updateSubmenuCellVisibility {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end

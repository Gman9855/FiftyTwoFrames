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
#import "FTFImage.h"

@interface FTFFiltersViewController () <UITextFieldDelegate>

typedef enum {
    FTFFilterSectionNameSearch,
    FTFFilterSectionExif,
    FTFFilterSectionMoreFilters,
    FTFFilterSectionSortBy
} FTFFilterSection;

typedef enum {
    FTFExifSectionExifDropdown,
    FTFExifSectionApertureSwitch,
    FTFExifSectionApertureSlider,
    FTFExifSectionShutterSpeedSwitch,
    FTFExifSectionShutterSpeedSlider,
    FTFExifSectionISOSwitch,
    FTFExifSectionISOSlider,
    FTFExifSectionFocalLengthSwitch,
    FTFExifSectionFocalLengthSlider,
} FTFExifSection;

typedef enum {
    FTFMoreFiltersSectionNewFramersSwitch,
    FTFMoreFiltersSectionExtraCreditChallengeSwitch,
    FTFMoreFiltersSectionCritiqueTypeDropdown,
    FTFMoreFiltersSectionCritiqueTypeRegular,
    FTFMoreFiltersSectionCritiqueTypeShredAway,
    FTFMoreFiltersSectionCritiqueTypeExtraSensitive,
    FTFMoreFiltersSectionCritiqueTypeNotInterested
} FTFMoreFiltersSection;

typedef enum {
    FTFSortBySectionDropdown,
    FTFSortBySectionDefault,
    FTFSortBySectionLikesAscending,
    FTFSortBySectionLikesDescending,
    FTFSortBySectionCommentsAscending,
    FTFSortBySectionCommentsDescending
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
@property (weak, nonatomic) IBOutlet UIImageView *sortByLikesAscendingCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByLikesDescendingCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByCommentsAscendingCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByCommentsDescendingCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *sortByDefaultImageView;
@property (weak, nonatomic) IBOutlet UIImageView *critiqueTypeRegularCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *critiqueTypeShredAwayCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *critiqueTypeExtraSensitiveCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *critiqueTypeNotInterestedCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *exposureDownArrow;
@property (weak, nonatomic) IBOutlet UIImageView *critiqueTypeDownArrow;
@property (weak, nonatomic) IBOutlet UIImageView *sortByDownArrow;
@property (weak, nonatomic) IBOutlet UILabel *sortByLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *resetButton;

@property (nonatomic, assign) BOOL exposureDropdownIsSelected;
@property (nonatomic, assign) BOOL sortByDropdownIsSelected;
@property (nonatomic, assign) BOOL sortByDefaultIsSelected;
@property (nonatomic, assign) BOOL sortByLikesAscendingIsSelected;
@property (nonatomic, assign) BOOL sortByLikesDescendingIsSelected;
@property (nonatomic, assign) BOOL sortByCommentsAscendingIsSelected;
@property (nonatomic, assign) BOOL sortByCommentsDescendingIsSelected;
@property (nonatomic, assign) BOOL critiqueTypeDropdownIsSelected;
@property (nonatomic, assign) BOOL critiqueTypeRegularIsSelected;
@property (nonatomic, assign) BOOL critiqueTypeShredAwayIsSelected;
@property (nonatomic, assign) BOOL critiqueTypeExtraSensitiveIsSelected;
@property (nonatomic, assign) BOOL critiqueTypeNotInterestedIsSelected;
@property (nonatomic, assign) BOOL isShowingFilteredResults;

@end

@implementation FTFFiltersViewController

- (NSArray *)switches {
    return @[self.apertureSwitch, self.focalLengthSwitch, self.shutterSpeedSwitch, self.ISOSwitch, self.extraCreditChallengeSwitch, self.framerNewSwitch];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setResetButtonHidden:YES];
    [self.searchTextField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(15, self.view.bounds.size.height - 54, self.view.bounds.size.width - 30, 44);
    saveButton.layer.cornerRadius = 5;
    saveButton.backgroundColor = [UIColor orangeColor];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont fontWithName:@"Lato-Bold" size:16];
    saveButton.alpha = 0.8;
    [saveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.view addSubview:saveButton];

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

- (void)saveButtonTapped:(UIButton *)sender {
    if (![self shouldSaveFilters]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops!" message:@"Looks like you missed something." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:alertAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    NSNumber *sortOrder = [NSNumber numberWithInt:FTFSortOrderNone];
    NSNumber *critiqueTypeRegular = [NSNumber numberWithInt:0];
    NSNumber *critiqueTypeShredAway = [NSNumber numberWithInt:0];
    NSNumber *critiqueTypeExtraSensitive = [NSNumber numberWithInt:0];
    NSNumber *critiqueTypeNotInterested = [NSNumber numberWithInt:0];
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
        focalLengthLowerValue = [NSNumber numberWithInteger:self.focalLengthRangeSlider.lowerValue];
        focalLengthUpperValue = [NSNumber numberWithInteger:self.focalLengthRangeSlider.upperValue];
    }
    
    if (self.shutterSpeedSwitch.isOn) {
        shutterSpeedLowerValue = [NSNumber numberWithDouble:self.shutterSpeedRangeSlider.lowerValueShutterSpeed];
        shutterSpeedUpperValue = [NSNumber numberWithDouble:self.shutterSpeedRangeSlider.upperValueShutterSpeed];
    }
    
    if (self.ISOSwitch.isOn) {
        ISOLowerValue = [NSNumber numberWithInteger:self.ISORangeSlider.lowerValueISO];
        ISOUpperValue = [NSNumber numberWithInteger:self.ISORangeSlider.upperValueISO];
    }
    
    if (self.sortByLikesAscendingIsSelected) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderLikesAscending];
    }
    
    if (self.sortByLikesDescendingIsSelected) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderLikesDescending];
    }
    
    if (self.sortByCommentsAscendingIsSelected) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderCommentsAscending];
    }
    
    if (self.sortByCommentsDescendingIsSelected) {
        sortOrder = [NSNumber numberWithInt:FTFSortOrderCommentsDescending];
    }
    
    if (self.critiqueTypeRegularIsSelected) {
        critiqueTypeRegular = [NSNumber numberWithInt:FTFImageCritiqueTypeRegular];
    }
    
    if (self.critiqueTypeShredAwayIsSelected) {
        critiqueTypeShredAway = [NSNumber numberWithInt:FTFImageCritiqueTypeShredAway];
    }
    
    if (self.critiqueTypeExtraSensitiveIsSelected) {
        critiqueTypeExtraSensitive = [NSNumber numberWithInt:FTFImageCritiqueTypeExtraSensitive];
    }
    
    if (self.critiqueTypeNotInterestedIsSelected) {
        critiqueTypeNotInterested = [NSNumber numberWithInt:FTFImageCritiqueTypeNotInterested];
    }
    
    NSDictionary *filtersDictionary = @{@"searchTerm" : self.searchTextField.text,
                                        @"sortOrder" : sortOrder,
                                        @"critiqueTypeRegular" : critiqueTypeRegular,
                                        @"critiqueTypeShredAway" : critiqueTypeShredAway,
                                        @"critiqueTypeExtraSensitive" : critiqueTypeExtraSensitive,
                                        @"critiqueTypeNotInterested" : critiqueTypeNotInterested,
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
    self.isShowingFilteredResults = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetButtonTapped:(UIBarButtonItem *)sender {
    if ([self shouldSaveFilters]) {
        [self resetFilters];
        
        if (self.isShowingFilteredResults) {
            [self.delegate filtersViewControllerDidResetFilters];
            self.isShowingFilteredResults = NO;
        }
        
        if ([self.searchTextField isFirstResponder]) {
            [self.searchTextField resignFirstResponder];
        }
        [self setResetButtonHidden:YES];
    }
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
    BOOL exposureSubSwitchIsOn = self.apertureSwitch.isOn || self.shutterSpeedSwitch.isOn || self.ISOSwitch.isOn || self.focalLengthSwitch.isOn;
    self.exposureDownArrow.image = [UIImage imageNamed:exposureSubSwitchIsOn ? @"DownArrow-Highlighted" : @"DownArrow-Regular"];
    [self updateSubmenuCellVisibility];
    
    [self setResetButtonHidden:![self shouldSaveFilters]];
}

- (IBAction)toggleResetButtonHidden:(id)sender {
    [self setResetButtonHidden:![self shouldSaveFilters]];
}

#pragma mark - UITableViewDelegate 

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case FTFFilterSectionExif:
            switch (indexPath.row) {
                case FTFExifSectionApertureSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExifSectionApertureSlider:
                    return self.apertureSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                case FTFExifSectionShutterSpeedSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExifSectionShutterSpeedSlider:
                    return self.shutterSpeedSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                case FTFExifSectionISOSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExifSectionISOSlider:
                    return self.ISOSwitch.on && self.exposureDropdownIsSelected ? 80 : 0;
                case FTFExifSectionFocalLengthSwitch:
                    return self.exposureDropdownIsSelected ? 44 : 0;
                case FTFExifSectionFocalLengthSlider:
                    return self.focalLengthSwitch.isOn && self.exposureDropdownIsSelected ? 80 : 0;
                default:
                    break;
            }
            break;
        case FTFFilterSectionMoreFilters:
            switch (indexPath.row) {
                case FTFMoreFiltersSectionCritiqueTypeRegular:
                    return self.critiqueTypeDropdownIsSelected ? 44 : 0;
                case FTFMoreFiltersSectionCritiqueTypeShredAway:
                    return self.critiqueTypeDropdownIsSelected ? 44 : 0;
                case FTFMoreFiltersSectionCritiqueTypeExtraSensitive:
                    return self.critiqueTypeDropdownIsSelected ? 44 : 0;
                case FTFMoreFiltersSectionCritiqueTypeNotInterested:
                    return self.critiqueTypeDropdownIsSelected ? 44 : 0;
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
    CATransition *transition = [CATransition animation];
    transition.duration = 0.2f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;

    switch (indexPath.section) {
        case FTFFilterSectionExif:
            switch (indexPath.row) {
                case FTFExifSectionExifDropdown:
                    self.exposureDropdownIsSelected = !self.exposureDropdownIsSelected;
                    [self updateSubmenuCellVisibility];
                    return nil;
                default:
                    break;
            }
            break;
        case FTFFilterSectionMoreFilters:
            switch (indexPath.row) {
                case FTFMoreFiltersSectionCritiqueTypeDropdown:
                    self.critiqueTypeDropdownIsSelected = !self.critiqueTypeDropdownIsSelected;
                    [self updateSubmenuCellVisibility];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:FTFMoreFiltersSectionCritiqueTypeNotInterested inSection:indexPath.section] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    
                    return nil;
                case FTFMoreFiltersSectionCritiqueTypeRegular:
                    self.critiqueTypeRegularIsSelected = !self.critiqueTypeRegularIsSelected;
                    break;
                case FTFMoreFiltersSectionCritiqueTypeShredAway:
                    self.critiqueTypeShredAwayIsSelected = !self.critiqueTypeShredAwayIsSelected;
                    break;
                case FTFMoreFiltersSectionCritiqueTypeExtraSensitive:
                    self.critiqueTypeExtraSensitiveIsSelected = !self.critiqueTypeExtraSensitiveIsSelected;
                    break;
                case FTFMoreFiltersSectionCritiqueTypeNotInterested:
                    self.critiqueTypeNotInterestedIsSelected = !self.critiqueTypeNotInterestedIsSelected;
                    break;
                default:
                    break;
            }
            self.critiqueTypeRegularCheckbox.image = [UIImage imageNamed:self.critiqueTypeRegularIsSelected ? @"Checked" : @"Unchecked"];
            self.critiqueTypeShredAwayCheckbox.image = [UIImage imageNamed:self.critiqueTypeShredAwayIsSelected ? @"Checked" : @"Unchecked"];
            self.critiqueTypeExtraSensitiveCheckbox.image = [UIImage imageNamed:self.critiqueTypeExtraSensitiveIsSelected ? @"Checked" : @"Unchecked"];
            self.critiqueTypeNotInterestedCheckbox.image = [UIImage imageNamed:self.critiqueTypeNotInterestedIsSelected ? @"Checked" : @"Unchecked"];
            
            [self.critiqueTypeRegularCheckbox.layer addAnimation:transition forKey:nil];
            [self.critiqueTypeShredAwayCheckbox.layer addAnimation:transition forKey:nil];
            [self.critiqueTypeExtraSensitiveCheckbox.layer addAnimation:transition forKey:nil];
            [self.critiqueTypeNotInterestedCheckbox.layer addAnimation:transition forKey:nil];
            
            BOOL critiqueTypeSubitemIsSelected = self.critiqueTypeRegularIsSelected || self.critiqueTypeShredAwayIsSelected || self.critiqueTypeExtraSensitiveIsSelected || self.critiqueTypeNotInterestedIsSelected;
            self.critiqueTypeDownArrow.image = [UIImage imageNamed:critiqueTypeSubitemIsSelected ? @"DownArrow-Highlighted" : @"DownArrow-Regular"];
            
            [self setResetButtonHidden:![self shouldSaveFilters]];
            
            return nil;
        case FTFFilterSectionSortBy:
            self.sortByDropdownIsSelected = !self.sortByDropdownIsSelected; // this results in closing the submenu cells after a selection is made
            self.sortByDefaultIsSelected = NO;
            self.sortByLikesAscendingIsSelected = NO;
            self.sortByLikesDescendingIsSelected = NO;
            self.sortByCommentsAscendingIsSelected = NO;
            self.sortByCommentsDescendingIsSelected = NO;

            switch (indexPath.row) {
                case FTFSortBySectionDropdown:
                    [self updateSubmenuCellVisibility];
                    if (!self.sortByDropdownIsSelected) {
                        if ([self.sortByLabel.text isEqualToString:@"Likes (Ascending)"]) {
                            self.sortByLikesAscendingIsSelected = YES;
                        }
                        
                        if ([self.sortByLabel.text isEqualToString:@"Likes (Descending)"]) {
                            self.sortByLikesDescendingIsSelected = YES;
                        }
                        
                        if ([self.sortByLabel.text isEqualToString:@"Comments (Ascending)"]) {
                            self.sortByCommentsAscendingIsSelected = YES;
                        }
                        
                        if ([self.sortByLabel.text isEqualToString:@"Comments (Descending)"]) {
                            self.sortByCommentsDescendingIsSelected = YES;
                        }
                    } else {
                        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:FTFSortBySectionCommentsDescending inSection:indexPath.section] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    }
                    
                    return nil;
                case FTFSortBySectionDefault:
                    self.sortByDefaultIsSelected = YES;
                    sortByLabelText = @"Default";
                    break;
                case FTFSortBySectionLikesAscending:
                    self.sortByLikesAscendingIsSelected = YES;
                    sortByLabelText = @"Likes (Ascending)";
                    break;
                case FTFSortBySectionLikesDescending:
                    self.sortByLikesDescendingIsSelected = YES;
                    sortByLabelText = @"Likes (Descending)";
                    break;
                case FTFSortBySectionCommentsAscending:
                    self.sortByCommentsAscendingIsSelected = YES;
                    sortByLabelText = @"Comments (Ascending)";
                    break;
                case FTFSortBySectionCommentsDescending:
                    self.sortByCommentsDescendingIsSelected = YES;
                    sortByLabelText = @"Comments (Descending)";
                    break;
                default:
                    break;
            }
        default:
            break;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.sortByLabel.text = sortByLabelText;
        [self updateSubmenuCellVisibility];
        [self setResetButtonHidden:![self shouldSaveFilters]];
    });
    
    BOOL sortBySubitemIsSelected = self.sortByCommentsAscendingIsSelected || self.sortByCommentsDescendingIsSelected || self.sortByLikesAscendingIsSelected || self.sortByLikesDescendingIsSelected;
    self.sortByDownArrow.image = [UIImage imageNamed:sortBySubitemIsSelected ? @"DownArrow-Highlighted" : @"DownArrow-Regular"];
    
    self.sortByCommentsAscendingCheckbox.image = [UIImage imageNamed:self.sortByCommentsAscendingIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByCommentsDescendingCheckbox.image = [UIImage imageNamed:self.sortByCommentsDescendingIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByLikesAscendingCheckbox.image = [UIImage imageNamed:self.sortByLikesAscendingIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByLikesDescendingCheckbox.image = [UIImage imageNamed:self.sortByLikesDescendingIsSelected ? @"Checked" : @"Unchecked"];
    self.sortByDefaultCheckbox.image = [UIImage imageNamed:self.sortByDefaultIsSelected ? @"Checked" : @"Unchecked"];
    
    [self.sortByCommentsAscendingCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByCommentsDescendingCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByLikesAscendingCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByCommentsDescendingCheckbox.layer addAnimation:transition forKey:nil];
    [self.sortByDefaultCheckbox.layer addAnimation:transition forKey:nil];

    return nil;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidChange:(id)sender {
    [self setResetButtonHidden:![self shouldSaveFilters]];
}

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
        self.exposureDownArrow.image = [UIImage imageNamed:@"DownArrow-Regular"];
        [self updateSubmenuCellVisibility];
    }
    
    if (!self.sortByDefaultIsSelected) {
        [self resetSortBySubitems];
    }
    
    if (self.critiqueTypeDropdownIsSelected) {
        self.critiqueTypeDropdownIsSelected = NO;
        [self updateSubmenuCellVisibility];
    }
    
    [self resetCritiqueTypeSubitems];
    
    
    self.searchTextField.text = @"";
}

- (BOOL)shouldSaveFilters {
    return ![self.searchTextField.text isEqualToString:@""] || self.framerNewSwitch.isOn || self.extraCreditChallengeSwitch.isOn || self.apertureSwitch.isOn || self.focalLengthSwitch.isOn || self.shutterSpeedSwitch.isOn || self.ISOSwitch.isOn || self.critiqueTypeRegularIsSelected || self.critiqueTypeShredAwayIsSelected || self.critiqueTypeExtraSensitiveIsSelected || self.critiqueTypeNotInterestedIsSelected || self.sortByLikesAscendingIsSelected || self.sortByLikesDescendingIsSelected || self.sortByCommentsAscendingIsSelected || self.sortByCommentsDescendingIsSelected;
}

- (void)updateSubmenuCellVisibility {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)resetExposureSubitems {
    [self.focalLengthRangeSlider resetKnobs];
    [self.apertureRangeSlider resetKnobs];
    [self.ISORangeSlider resetKnobs];
    [self.shutterSpeedRangeSlider resetKnobs];
    self.exposureDownArrow.image = [UIImage imageNamed:@"DownArrow-Regular"];
}

- (void)resetSortBySubitems {
    self.sortByDownArrow.image = [UIImage imageNamed:@"DownArrow-Regular"];
    self.sortByCommentsAscendingCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.sortByCommentsDescendingCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.sortByLikesAscendingCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.sortByLikesDescendingCheckbox.image = [UIImage imageNamed:@"Unchecked"];

    self.sortByDefaultCheckbox.image = [UIImage imageNamed:@"Checked"];
    self.sortByCommentsAscendingIsSelected = NO;
    self.sortByCommentsDescendingIsSelected = NO;
    self.sortByLikesAscendingIsSelected = NO;
    self.sortByLikesDescendingIsSelected = NO;
    self.sortByDefaultIsSelected = YES;
    self.sortByLabel.text = @"Default";
}

- (void)resetCritiqueTypeSubitems {
    self.critiqueTypeRegularIsSelected = NO;
    self.critiqueTypeShredAwayIsSelected = NO;
    self.critiqueTypeExtraSensitiveIsSelected = NO;
    self.critiqueTypeNotInterestedIsSelected = NO;
    self.critiqueTypeRegularCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.critiqueTypeShredAwayCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.critiqueTypeExtraSensitiveCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.critiqueTypeNotInterestedCheckbox.image = [UIImage imageNamed:@"Unchecked"];
    self.critiqueTypeDownArrow.image = [UIImage imageNamed:@"DownArrow-Regular"];
}

- (void)setResetButtonHidden:(BOOL)hidden {
    NSMutableArray *navBarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
    if (hidden) {
        [navBarButtons removeObject:self.resetButton];
        [self.navigationItem setRightBarButtonItems:navBarButtons];
    } else {
        if (![navBarButtons containsObject:self.resetButton]) {
            [navBarButtons addObject:self.resetButton];
            [self.navigationItem setRightBarButtonItems:navBarButtons];
        }
    }
}

@end

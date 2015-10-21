//
//  FTFAlbumDescriptionViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 3/3/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

#import "FTFAlbumDescriptionViewController.h"
#import "FTFAlbum.h"

@interface FTFAlbumDescriptionViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation FTFAlbumDescriptionViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setAlbum:(FTFAlbum *)album {
    _album = album;
    [self _updateText];
}

- (void)_updateText;
{
//    self.title = self.album.name;
//    [self.navigationController.navigationBar setTitleTextAttributes:
//     @{NSForegroundColorAttributeName:[UIColor orangeColor]}];
    self.textView.text = self.album.info;
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    self.textView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    [self _updateText];
}

- (IBAction)tappedInView:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.textView setContentOffset:CGPointZero animated:YES];
//    CGRect newFrame = self.view.frame;
//    
//    newFrame.size.width = 200;
//    newFrame.size.height = 200;
//    [self.view setFrame:newFrame];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

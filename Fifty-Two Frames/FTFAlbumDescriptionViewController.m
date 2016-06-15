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
}

- (void)setAlbum:(FTFAlbum *)album {
    _album = album;
    [self _updateText];
}

- (void)_updateText;
{
    self.textView.text = self.album.info;
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    [self _updateText];
}

- (IBAction)tappedInView:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end

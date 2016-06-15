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
    [self.textView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];
    [self _updateText];
}

- (IBAction)tappedInView:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UITextView *tv = object;
    CGFloat topCorrect = ([tv bounds].size.height - [tv     contentSize].height * [tv zoomScale])/2.0;
    topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    [tv setContentInset:UIEdgeInsetsMake(topCorrect,0,0,0)];
}

- (void)dealloc {
    [self.textView removeObserver:self forKeyPath:@"contentSize"];
}

@end

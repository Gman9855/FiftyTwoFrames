//
//  FTFPhotoViewController.m
//  Fifty-Two Frames
//
//  Created by Gershy Lev on 6/14/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoViewController.h"

@interface FTFPhotoViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *pagingScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation FTFPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoSingleTapped:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapRecognizer];
    

    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [self requestPhoto];

    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:0.5 animations:^{
        self.navigationController.navigationBar.alpha = 0.0;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpPagingScrollView;
{
    CGRect pagingScrollViewFrame = [[UIScreen mainScreen] bounds];
    pagingScrollViewFrame.origin.x -= 10;
    pagingScrollViewFrame.size.width += 20;
    self.pagingScrollView.frame = pagingScrollViewFrame;
    
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.backgroundColor = [UIColor blackColor];
    self.pagingScrollView.contentSize = CGSizeMake(pagingScrollViewFrame.size.width * self.photoCount, pagingScrollViewFrame.size.height);
    self.view = self.pagingScrollView;
    
    // Add pages to scroll view
    
    for (int i = 0; i < self.photoCount; i++) {
        
    }
}

- (void)requestPhoto;
{
    [self.photo requestImageWithSize:FTFImageSizeLarge
            completionBlock:^(UIImage *image, NSError *error, BOOL isCached) {
                if (error) {
                    //...
                    return;
                }
                //self.imageView.bounds = (CGRect){{}, image.size};
                //self.scrollView.contentSize = image.size;
                //self.imageView.image = image;
                CGFloat ratio = CGRectGetWidth(self.scrollView.bounds) / image.size.width;
                self.imageView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), image.size.height * ratio);
                self.imageView.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds));
                self.imageView.image = image;
                self.scrollView.clipsToBounds = YES;
                self.scrollView.contentSize = self.imageView.bounds.size;
            }];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIView *subView = self.imageView;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)photoSingleTapped:(UITapGestureRecognizer*)recognizer {
    [UIView animateWithDuration:0.4 animations:^{
        if (self.navigationController.navigationBar.alpha == 1.0) {
            self.navigationController.navigationBar.alpha = 0.0;
        } else {
            self.navigationController.navigationBar.alpha = 1.0;
        }
    }];
}

- (void)photoDoubleTapped:(UITapGestureRecognizer*)recognizer {
    CGPoint pointInView = [recognizer locationInView:self.imageView];
    
    // 2
    CGFloat newZoomScale = self.scrollView.zoomScale * 3.0f;
    newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
    
    // 3
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    // 4
    [self.scrollView zoomToRect:rectToZoomTo animated:YES];
}

- (IBAction)photoPinched:(UIPinchGestureRecognizer *)sender {
}

- (IBAction)photoPanned:(UIPanGestureRecognizer *)sender {
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

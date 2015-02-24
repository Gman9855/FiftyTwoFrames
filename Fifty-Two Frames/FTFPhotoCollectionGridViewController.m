//
//  FTFPhotoCollectionViewController.m
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 9/6/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFPhotoCollectionGridViewController.h"
#import "FTFImage.h"
#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"
#import "FTFCollectionViewCell.h"
#import "MWPhotoBrowser.h"

@interface FTFPhotoCollectionGridViewController ()

@end

@implementation FTFPhotoCollectionGridViewController

#pragma mark - View controller

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
    [self addObserver:self forKeyPath:@"gridPhotos" options:NSKeyValueObservingOptionNew context:NULL];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.gridPhotos.count) {
        [MBProgressHUD showHUDAddedTo:self.collectionView animated:YES];
    }
    self.navigationController.toolbarHidden = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"gridPhotos"]) {
        [self.collectionView reloadData];
//        if (self.gridPhotos.count) {
//            NSIndexPath *firstIndexPathInCollectionView = [NSIndexPath indexPathForItem:0 inSection:0];
//            [self.collectionView scrollToItemAtIndexPath:firstIndexPathInCollectionView
//                                        atScrollPosition:UICollectionViewScrollPositionTop
//                                                animated:YES];
//        }
    }
}

#pragma mark - Navigation Controller Delegate

//- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
//                                  animationControllerForOperation:(UINavigationControllerOperation)operation
//                                               fromViewController:(UIViewController *)fromVC
//                                                 toViewController:(UIViewController *)toVC
//{
//    
//}

#pragma mark - Collection View Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.gridPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    FTFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                                           forIndexPath:indexPath];
    FTFImage *photoAtIndex = self.gridPhotos[indexPath.row];
    if (photoAtIndex) {
        [MBProgressHUD hideHUDForView:self.collectionView animated:NO];
    }
    [cell.thumbnailView setImageWithURL:photoAtIndex.smallPhotoURL
                  placeholderImage:[UIImage imageNamed:@"placeholder"]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate photoCollectionGridDidSelectPhotoAtIndex:indexPath.row];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

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
#import "FiftyTwoFrames.h"
#import "FTFCollectionReusableView.h"

@interface FTFPhotoCollectionGridViewController ()

@property (nonatomic, strong) FTFCollectionReusableView *collectionReusableView;

@end

@implementation FTFPhotoCollectionGridViewController {
    BOOL _albumSelectionChanged;
    BOOL _morePhotosToLoad;
    BOOL _finishedPaging;
}

#pragma mark - View controller

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    [self addObserver:self forKeyPath:@"gridPhotos" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumSelectionChanged:)
                                                 name:@"albumSelectedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateForAlbumWithNoPaging:)
                                                 name:@"albumDoesNotNeedToBePagedNotification"
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    }
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    _albumSelectionChanged = YES;
    _finishedPaging = NO;
    NSIndexPath *firstIndexPathInCollectionView = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:firstIndexPathInCollectionView
                                atScrollPosition:UICollectionViewScrollPositionTop
                                        animated:NO];
    _albumSelectionChanged = NO;
}

- (void)updateForAlbumWithNoPaging:(NSNotification *)notification {
    _finishedPaging = YES;
}

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

    if (indexPath.row == self.gridPhotos.count - 4) {
        _morePhotosToLoad = YES;
    }
    
    [cell.thumbnailView setImageWithURL:photoAtIndex.smallPhotoURL
                       placeholderImage:[UIImage imageNamed:@"placeholder"]
                                options:SDWebImageRetryFailed
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    if (cacheType == SDImageCacheTypeNone) {
                                        CATransition *t = [CATransition animation];
                                        t.duration = 0.30;
                                        t.type = kCATransitionFade;
                                        [cell.thumbnailView.layer addAnimation:t forKey:@"ftf"];
                                    }

                                    cell.thumbnailView.image = image;
    }];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate photoCollectionGridDidSelectPhotoAtIndex:indexPath.row];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    self.collectionReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
    
    if (_finishedPaging || !self.gridPhotos.count) {
        self.collectionReusableView.spinner.hidden = YES;
    } else {
        self.collectionReusableView.spinner.hidden = NO;
        [self.collectionReusableView.spinner startAnimating];
    }
    
    return self.collectionReusableView;
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -150;
    if(y > h + reload_distance && self.gridPhotos && _morePhotosToLoad) {
        _morePhotosToLoad = NO;
        NSLog(@"Grid hit the bottom");
        if (!_finishedPaging) {
            [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosWithCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                _finishedPaging = finishedPaging;
                NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
                [albumPhotos addObjectsFromArray:photos];
                self.gridPhotos = [albumPhotos copy];
                NSNumber *isFinishedPaging = [NSNumber numberWithBool:finishedPaging];
                NSDictionary *updatedAlbumPhotos = [NSDictionary dictionaryWithObjectsAndKeys:albumPhotos, @"albumPhotos", isFinishedPaging, @"finishedPaging", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"photoGridDidPageMorePhotosNotification"
                                                                    object:nil
                                                                  userInfo:updatedAlbumPhotos];
                _morePhotosToLoad = YES;
            }];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

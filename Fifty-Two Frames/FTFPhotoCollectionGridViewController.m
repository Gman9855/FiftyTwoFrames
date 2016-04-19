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
#import "FTFCollectionViewListCell.h"
#import "FTFCollectionViewGridCell.h"
#import "MWPhotoBrowser.h"
#import "FiftyTwoFrames.h"
#import "FTFCollectionReusableView.h"
#import "FiftyTwoFrames-Swift.h"
#import "FTFGridLayout.h"
#import "CHTCollectionViewWaterfallLayout.h"
@interface FTFPhotoCollectionGridViewController () <CHTCollectionViewDelegateWaterfallLayout>

@property (nonatomic, strong) FTFCollectionReusableView *collectionReusableView;
@property (nonatomic, strong) UILabel *navBarTitle;
@property (nonatomic, strong) FTFListLayout *listLayout;
@property (nonatomic, strong) CHTCollectionViewWaterfallLayout *gridLayout;
@property (nonatomic, strong) UICollectionViewLayout *currentLayout;
@property (nonatomic, assign) BOOL shouldReloadData;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *layoutToggleButton;

@end

@implementation FTFPhotoCollectionGridViewController {
    BOOL _albumSelectionChanged;
    BOOL _morePhotosToLoad;
    BOOL _finishedPaging;
    BOOL _didUpdateCells;
    BOOL _layoutDidChange;
}

- (UILabel *)navBarTitle {
    if (!_navBarTitle) {
        _navBarTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 85)];
        _navBarTitle.textAlignment = NSTextAlignmentCenter;
        _navBarTitle.textColor = [UIColor whiteColor];
        _navBarTitle.font = [UIFont boldSystemFontOfSize:14];
        _navBarTitle.numberOfLines = 2;
        self.navigationItem.titleView = _navBarTitle;
    }
    return _navBarTitle;
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
    self.shouldReloadData = YES;
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
    self.listLayout = [[FTFListLayout alloc] init];
    self.gridLayout = [[CHTCollectionViewWaterfallLayout alloc] init];
    self.gridLayout.columnCount = 2;
    self.gridLayout.minimumColumnSpacing = 5;
    self.gridLayout.minimumInteritemSpacing = 5;
    self.collectionView.collectionViewLayout = self.listLayout;
    self.currentLayout = self.listLayout;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self setNavBarTitleWithAttributedText];
    [self setListbutton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"gridPhotos"]) {
        if (self.shouldReloadData) {
            [self.collectionView reloadData];
        }
    }
}

- (void)albumSelectionChanged:(NSNotification *)notification {
    _albumSelectionChanged = YES;
    _finishedPaging = NO;
    if (self.gridPhotos) {
        NSIndexPath *firstIndexPathInCollectionView = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:firstIndexPathInCollectionView
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
    
    _albumSelectionChanged = NO;
}

- (void)updateForAlbumWithNoPaging:(NSNotification *)notification {
    _finishedPaging = YES;
}

#pragma mark - Action Methods


- (IBAction)albumMenuButtonTapped:(UIBarButtonItem *)sender {
    UINavigationController *albumSelectionMenuNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"albumListNavController"];
    [self presentViewController:albumSelectionMenuNavigationController animated:true completion:nil];
}

- (IBAction)toggleLayout:(UIBarButtonItem *)sender {
    _layoutDidChange = YES;
    UICollectionViewLayout *layout;
    NSString *layoutType;
    NSString *toolbarIconImageName;
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        layout = self.gridLayout;
        layoutType = @"grid";
        self.navigationItem.rightBarButtonItem.title = @"List";
        toolbarIconImageName = @"DefaultStyle";
    } else {
        layout = self.listLayout;
        layoutType = @"list";
        self.navigationItem.rightBarButtonItem.title = @"Grid";
        toolbarIconImageName = @"UIBarButtonItemGrid";
    }
    self.currentLayout = layout;
    self.layoutToggleButton.image = [UIImage imageNamed:toolbarIconImageName];
    
    NSDictionary *userInfo = @{@"layout": layout, @"layoutType": layoutType};
    
    NSArray *visibleCells = [self.collectionView visibleCells];
    FTFCollectionViewCell *firstPhoto = (FTFCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    BOOL containsFirstPhoto = [visibleCells containsObject:firstPhoto];
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.865 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        [self.collectionView setCollectionViewLayout:layout animated:NO];
        if (containsFirstPhoto) {
            [self.collectionView setContentOffset:CGPointZero];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        
        [self postLayoutNotification:userInfo];
        
    } completion:nil];
}

- (IBAction)albumInfoButtonTapped:(UIBarButtonItem *)sender {
    
}

#pragma mark - Collection View Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.gridPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"collectionViewCell";
    
    FTFCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                     forIndexPath:indexPath];
    
    FTFImage *photoAtIndex = self.gridPhotos[indexPath.row];
    if (photoAtIndex) {
        [MBProgressHUD hideHUDForView:self.collectionView animated:NO];
    }

    if (indexPath.row == self.gridPhotos.count - 4) {
        _morePhotosToLoad = YES;
    }
    
    [cell updateCellsForLayout:self.currentLayout];
    
    [cell.thumbnailView setImageWithURL:photoAtIndex.smallPhotoURL
                       placeholderImage:[UIImage imageNamed:@"placeholder"]
                                options:SDWebImageRetryFailed
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    if (cacheType == SDImageCacheTypeNone || cacheType == SDImageCacheTypeDisk) {
                                        CATransition *t = [CATransition animation];
                                        t.duration = 0.12;
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
    if (![kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return nil;
    } else {
        self.collectionReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        
        if (_finishedPaging || !self.gridPhotos.count) {
            self.collectionReusableView.spinner.hidden = YES;
        } else {
            self.collectionReusableView.spinner.hidden = NO;
            [self.collectionReusableView.spinner startAnimating];
        }
    }
    
    return self.collectionReusableView;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
//    return CGSizeMake(0.0f, 0.0f);
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(50.0f, 50.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewLayout == self.gridLayout) {
        FTFImage *photo = self.gridPhotos[indexPath.row];
        return photo.smallPhotoSize;
    }
    
    return self.listLayout.itemSize;
}


#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -300;
    if(y > h + reload_distance && self.gridPhotos && _morePhotosToLoad && !_layoutDidChange) {
        _morePhotosToLoad = NO;
        NSLog(@"Grid hit the bottom");
        if (!_finishedPaging) {
            [[FiftyTwoFrames sharedInstance] requestNextPageOfAlbumPhotosWithCompletionBlock:^(NSArray *photos, NSError *error, BOOL finishedPaging) {
                _finishedPaging = finishedPaging;
                
                NSMutableArray *albumPhotos = [self.gridPhotos mutableCopy];
                [albumPhotos addObjectsFromArray:photos];
                self.shouldReloadData = NO;
                NSInteger gridPhotosCount = self.gridPhotos.count;
                self.gridPhotos = [albumPhotos copy];
                self.shouldReloadData = YES;
                
                [self.collectionView performBatchUpdates:^{
                    NSMutableArray *indexPaths = [NSMutableArray new];
                    for (NSInteger i = gridPhotosCount; i < gridPhotosCount + photos.count; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                        [indexPaths addObject:ip];
                    }
                    [self.collectionView insertItemsAtIndexPaths:indexPaths];

                } completion:nil];
                
                
                NSNumber *isFinishedPaging = [NSNumber numberWithBool:finishedPaging];
                NSDictionary *updatedAlbumPhotos = [NSDictionary dictionaryWithObjectsAndKeys:albumPhotos, @"albumPhotos", isFinishedPaging, @"finishedPaging", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"photoGridDidPageMorePhotosNotification"
                                                                    object:nil
                                                                  userInfo:updatedAlbumPhotos];
                _morePhotosToLoad = YES;
            }];
        }
    }
    _layoutDidChange = NO;
}

#pragma mark - Helper Methods

- (void)setNavBarTitleWithAttributedText {
    if ([self.albumName containsString:@":"]) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:self.albumName];
        NSArray *words = [self.albumName componentsSeparatedByString:@": "];
        NSString *albumName = [words firstObject];
        NSRange range = [self.albumName rangeOfString:albumName];
        range.length++;
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:range];
        [self.navBarTitle setAttributedText:attributedString];
    } else {
        self.navBarTitle.text = self.albumName;
    }
}

- (void)setListbutton {
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithTitle:@"Grid"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(changeLayout)];
    self.navigationItem.rightBarButtonItem = listButton;
}

-(void)postLayoutNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"LayoutDidChange"
     object:self userInfo:userInfo];
}

-(void)changeLayout {
    _layoutDidChange = YES;
    UICollectionViewLayout *layout;
    NSString *layoutType;
    if (self.collectionView.collectionViewLayout == self.listLayout) {
        layout = self.gridLayout;
        layoutType = @"grid";
        self.navigationItem.rightBarButtonItem.title = @"List";
    } else {
        layout = self.listLayout;
        layoutType = @"list";
        self.navigationItem.rightBarButtonItem.title = @"Grid";
    }
    
    self.currentLayout = layout;
    
    NSDictionary *userInfo = @{@"layout": layout, @"layoutType": layoutType};
    
    NSArray *visibleCells = [self.collectionView visibleCells];
    FTFCollectionViewCell *firstPhoto = (FTFCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    BOOL containsFirstPhoto = [visibleCells containsObject:firstPhoto];
    
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.865 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.collectionView setCollectionViewLayout:layout animated:NO];
        if (containsFirstPhoto) {
            [self.collectionView setContentOffset:CGPointZero];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        
        [self postLayoutNotification:userInfo];

    } completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"gridPhotos" context:NULL];
}

@end

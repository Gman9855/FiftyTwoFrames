//
//  FTFCollectionViewListCell.h
//  FiftyTwoFrames
//
//  Created by Gershy Lev on 3/20/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTFCollectionViewCell.h"

@interface FTFCollectionViewListCell : FTFCollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UIView *bottomDetailView;

@end

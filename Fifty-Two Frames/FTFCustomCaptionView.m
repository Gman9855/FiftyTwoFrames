//
//  FTFCustomCaptionView.m
//  FiftyTwoFrames
//
//  Created by Gershon Lev on 9/16/14.
//  Copyright (c) 2014 Gershy Lev. All rights reserved.
//

#import "FTFCustomCaptionView.h"

static const CGFloat labelPadding = 10;

@interface FTFCustomCaptionView () {
    id <MWPhoto> _photo;
    UIToolbar *_contentView;
    UITextView *_textView;
}
@end

@implementation FTFCustomCaptionView

- (id)initWithPhoto:(id<MWPhoto>)photo {
    self = [super initWithPhoto:photo];
    if (self) {
        _photo = photo;
        _textView.scrollEnabled = NO;
        self.userInteractionEnabled = YES;
        [self setupCaption];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat maxHeight = screenBounds.size.height / 8;
    CGSize textSize = [_textView.text boundingRectWithSize:CGSizeMake(size.width - labelPadding * 2, maxHeight)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:_textView.font}
                                                   context:nil].size;

    return CGSizeMake(size.width, textSize.height + labelPadding * 5);
}

- (void)setupCaption {
    _contentView = [[UIToolbar alloc] initWithFrame:self.bounds];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    _contentView.barStyle = UIBarStyleBlackTranslucent;
    _contentView.tintColor = nil;
    _contentView.barTintColor = nil;
    _contentView.barStyle = UIBarStyleBlackTranslucent;
    [_contentView setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    self.layer.allowsGroupOpacity = NO;
    
    [self addSubview:_contentView];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectIntegral(CGRectMake(labelPadding, 0,
                                                                            self.bounds.size.width - labelPadding * 2,
                                                                            self.bounds.size.height))];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _textView.opaque = NO;
    _textView.editable = NO;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textAlignment = NSTextAlignmentCenter;
    _textView.textColor = [UIColor whiteColor];
    _textView.font = [UIFont systemFontOfSize:12];
    if ([_photo respondsToSelector:@selector(caption)]) {
        _textView.text = [_photo caption] ? [_photo caption] : @" ";
    }
    _textView.contentOffset = CGPointZero;
    [_textView scrollRangeToVisible:NSMakeRange(0, 0)];
    _textView.scrollEnabled = YES;

    [_contentView addSubview:_textView];
}

@end

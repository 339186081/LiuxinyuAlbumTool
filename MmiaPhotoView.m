//
//  MmiaPhotoView.m
//  VIPhotoViewDemo
//
//  Created by liuxinyu on 15/12/22.
//  Copyright © 2015年 vito. All rights reserved.
//

#import "MmiaPhotoView.h"
#import "UIImageView+WebCache.h"
#import "MmiaActionSheet.h"
#import "MmiaPhotoAlbum.h"
#import "SVProgressHUD.h"

static CGFloat minScale = 1.0;

@interface UIImage (Mmia)

- (CGSize)sizeThatFits:(CGSize)size;

@end

@implementation UIImage (Mmia)

- (CGSize)sizeThatFits:(CGSize)size
{
    // 图片的逻辑大小 = 图片的实际大小 / scale
    CGSize imageSize = CGSizeMake(self.size.width / self.scale,
                                  self.size.height / self.scale);

    CGFloat widthRatio = imageSize.width / size.width;
    CGFloat heightRatio = imageSize.height / size.height;
    
    if (widthRatio > heightRatio) {
        imageSize = CGSizeMake(imageSize.width / widthRatio, imageSize.height / widthRatio);
    } else {
        imageSize = CGSizeMake(imageSize.width / heightRatio, imageSize.height / heightRatio);
    }
    
    return imageSize;
}

@end

@interface UIImageView (Mmia)

- (CGSize)contentSize;

@end

@implementation UIImageView (Mmia)

- (CGSize)contentSize
{
    
    return [self.image sizeThatFits:self.bounds.size];
}

@end

@interface MmiaPhotoView () <UIScrollViewDelegate,MmiaSheetDelegate,UIGestureRecognizerDelegate> {
    
}

@property (nonatomic, strong) UIView *containerView;


@property (nonatomic) BOOL rotating;
@property (nonatomic) CGSize minSize;

@end

@implementation MmiaPhotoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.delegate = self;
        self.userInteractionEnabled = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self setupGestureRecognizer];


    }
    
    return self;
}

#pragma mark - public methods

- (void)showImage {
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.imageUrl] placeholderImage:nil options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        CGSize imageSize = CGSizeMake((int)_imageView.contentSize.width, (int)_imageView.contentSize.height);
        _containerView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showImageAnimationWithSize:imageSize];
        });
        
        self.contentSize = imageSize;
        self.minSize = imageSize;
        
        [self setMaxMinZoomScale];
        
        [self centerContent];

    }];
}

/**
 *  双击改变大小
 *
 *  @param recognizer 手势
 */
- (void)changeScale:(UIGestureRecognizer *)recognizer
{
    
    if (self.zoomScale > minScale) {
        [self setZoomScale:minScale animated:YES];
    }
    else if (self.zoomScale < self.maximumZoomScale) {
        
        
        [self setZoomScale:2 animated:YES];
    }
}

/**
 *  当然图片滚动出界面，还原其大小
 */
- (void)restoreThePhotoSize
{
    if (self.zoomScale > self.minimumZoomScale) {
        [self setZoomScale:self.minimumZoomScale animated:YES];
    }
}

#pragma mark - view related methods

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.rotating) {
        self.rotating = NO;
        
        // update container view frame
        CGSize containerSize = self.containerView.frame.size;
        
        BOOL containerSmallerThanSelf = (containerSize.width < CGRectGetWidth(self.bounds)) && (containerSize.height < CGRectGetHeight(self.bounds));
        
        CGSize imageSize = [self.imageView.image sizeThatFits:self.bounds.size];
        CGFloat minZoomScale = imageSize.width / self.minSize.width;
        self.minimumZoomScale = minZoomScale;
        if (containerSmallerThanSelf || self.zoomScale == self.minimumZoomScale) { // 宽度或高度 都小于 self 的宽度和高度
            self.zoomScale = minZoomScale;
        }
        // Center container view
        [self centerContent];
    }
}

#pragma mark - MmiaActionSheet delegate

- (void)selectedMmiaSheetWith:(MmiaActionSheet *)mmiaSheet index:(NSInteger)index {
    switch (index) {
        case 0:
        {
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }
            break;
        case 1:
        {
            if ([self.photoDelegate respondsToSelector:@selector(reportPhotoWithTag:)]) {
                [self.photoDelegate reportPhotoWithTag:self.tag];
            }
        }
        default:
            break;
    }
}

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.containerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerContent];
    
}

#pragma mark - event methods

// 长按
- (void)longPress:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        MmiaActionSheet *sheet = [[MmiaActionSheet alloc]initLXYSheetWithArray:@[@"保存图片",@"举报"]];
        sheet.delegate = self;
        
        [sheet showInView];
    }
}

/**
 *  单击隐藏
 */
- (void)singleTap
{
    MmiaPhotoAlbum *photo = (MmiaPhotoAlbum *)self.superview.superview;
    if (self.firstSelectedPhoto) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGRect frame = [window convertRect:self.originalFrame toView:_containerView];
        [UIView animateWithDuration:0.3 animations:^{
            _imageView.frame = frame;
            photo.backgroundColor = [UIColor clearColor];
            
        } completion:^(BOOL finished) {
            photo.alpha = 0;
            [photo removeFromSuperview];
        }];
    }
    else {
        if ([self.photoDelegate respondsToSelector:@selector(scrollToImageWithTag:)]) {
            [self.photoDelegate scrollToImageWithTag:self.tag];
        }
    }
}

#pragma mark - private methods

- (void)setupGestureRecognizer
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
    longPress.minimumPressDuration = 0.8;
    [self addGestureRecognizer:longPress];
    
    // 单击
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.delaysTouchesBegan = YES;
    [self addGestureRecognizer:singleTap];
    
    // 双击
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeScale:)];
    doubleTap.numberOfTapsRequired = 2;
    
    [self addGestureRecognizer:doubleTap];
    
    // 只有双击操作无法识别的时候，才识别单击操作
    [singleTap requireGestureRecognizerToFail:doubleTap];
}

- (void)showImageAnimationWithSize:(CGSize)imageSize {
    if (self.firstShow) {
        self.firstShow = NO;
        MmiaPhotoAlbum *photo = (MmiaPhotoAlbum *)self.superview.superview;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGRect frame = [window convertRect:self.originalFrame toView:_containerView];
        _imageView.frame = frame;
        _imageView.alpha = 1;
        [UIView animateWithDuration:0.5 animations:^{
            photo.backgroundColor = [UIColor blackColor];
            _imageView.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
            _imageView.center = CGPointMake(imageSize.width / 2, imageSize.height / 2);
        }];
    }
    else {
        _imageView.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
        _imageView.center = CGPointMake(imageSize.width / 2, imageSize.height / 2);
        _imageView.alpha = 1;
    }
}

// 保存图片的回调
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(!error){
        [SVProgressHUD showSuccessWithStatus:@"已保存到系统相册"];
    }else{
        
    }
}

// 设置最大最小缩放规模
- (void)setMaxMinZoomScale {

    self.maximumZoomScale = 3;
    self.minimumZoomScale = minScale;
}

// 设置图片显示在中间
- (void)centerContent {
    CGRect containerFrame = self.containerView.frame;
    
    CGFloat top = 0, left = 0;
    if (self.contentSize.width < self.bounds.size.width) {
        left = (self.bounds.size.width-self.contentSize.width)/2;
    }
    if (self.contentSize.height < self.bounds.size.height) {
        top = (self.bounds.size.height - self.contentSize.height)/2;
    }
    top -= containerFrame.origin.y;
    left -= containerFrame.origin.x;
    
    self.contentInset = UIEdgeInsetsMake(top, left, top, left);
}


#pragma mark - Setup 旋转
- (void)setupRotationNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}
#pragma mark - Notification
- (void)orientationChanged:(NSNotification *)notification
{
    self.rotating = YES;
}

#pragma mark - get methods
- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_containerView];
    }
    return _containerView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.alpha = 0;
        [self.containerView addSubview:_imageView];
    }
    return _imageView;
}

@end

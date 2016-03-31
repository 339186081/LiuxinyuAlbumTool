//
//  LXYPhotoView.m
//  HospitalContactor
//
//  Created by lxy on 15/1/4.
//  Copyright (c) 2015年 lxy. All rights reserved.
//

#import "MmiaPhotoAlbum.h"
#import "UIImageView+WebCache.h"
#import "MmiaPhotoView.h"

#define kPadding 10

#define HEIGHT self.frame.size.height

#define WIDTH self.frame.size.width

@interface MmiaPhotoAlbum() <MmiaPhotoViewDelegate> {
    UIScrollView *mainScrollView;

    UILabel *indexlabel;


    NSMutableArray *visiblePhotoArray;
    
    NSMutableArray *reusablePhotoArray;
    
    BOOL firstShow;
}


@end

@implementation MmiaPhotoAlbum


//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
////        [self createContent];
//    }
//    return self;
//}

- (instancetype)initWithArray:(NSArray *)array
{
    self = [super init];
    if (self) {
        CGRect rect = [[UIScreen mainScreen]bounds];
        self.backgroundColor = [UIColor clearColor];
        firstShow = YES;
        self.frame = rect;
        if (array.count > 1) {
            visiblePhotoArray = [NSMutableArray array];
            reusablePhotoArray = [NSMutableArray array];
        }
        self.imageArray = array;
        [self createContent];
    }
    return  self;
}

- (void)setCurIndex:(NSInteger)curIndex {
    _curIndex = curIndex;
    
    indexlabel.text = [NSString stringWithFormat:@"%tu/%tu",_curIndex+1,_imageArray.count];
}

#pragma  mark Initialization
- (void)createContent
{
    mainScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(-kPadding, 0, WIDTH+2*kPadding, HEIGHT)];
    mainScrollView.delegate=self;
    mainScrollView.userInteractionEnabled = YES;
    mainScrollView.showsHorizontalScrollIndicator=NO;
    mainScrollView.pagingEnabled=YES;
    mainScrollView.backgroundColor=[UIColor clearColor];
    [self addSubview:mainScrollView];
    
    mainScrollView.contentSize = CGSizeMake((WIDTH+2*kPadding)*self.imageArray.count, 0);

    indexlabel = [[UILabel alloc]initWithFrame:CGRectMake(WIDTH/2-50, HEIGHT-12-20, 100, 20)];
    indexlabel.font = [UIFont systemFontOfSize:12];
    indexlabel.textColor = [UIColor whiteColor];
    indexlabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:indexlabel];
    if (self.imageArray.count == 1) {
        indexlabel.hidden = YES;
    }
}

- (void)showPhotos {
    if (self.imageArray.count == 0) {
        [self showPhotoAtIndex:0];
    }
    else {
        NSInteger firstIndex = _curIndex-1;
        NSInteger nextIndex = _curIndex+1;
        
        if (firstIndex < 0) firstIndex = 0;
        if (nextIndex >= _imageArray.count) nextIndex = _imageArray.count - 1;
        
        // 回收不再显示的ImageView
        NSInteger photoViewIndex;
        NSArray *tempArray = [NSArray arrayWithArray:visiblePhotoArray];
        
        for (MmiaPhotoView *photoView in tempArray) {
            photoViewIndex = photoView.tag - kPhotoTag;
            if (photoViewIndex < firstIndex || photoViewIndex > nextIndex) {
                [reusablePhotoArray addObject:photoView];
                [visiblePhotoArray removeObject:photoView];
                [photoView removeFromSuperview];
            }
        }
        while (reusablePhotoArray.count > 2) {
            [reusablePhotoArray removeObjectAtIndex:0];
        }

        for (NSInteger index = firstIndex; index <= nextIndex; index++) {
            if (![self isShowingPhotoViewAtIndex:index]) {
                [self showPhotoAtIndex:index];
            }
        }
    }
}

- (void)showPhotoAtIndex:(NSInteger )index {

    MmiaPhotoView *photoView = [self dequeResuableImageViewWithIndex:index];

    if (!photoView) {
        NSString *imageUrl = [self.imageArray objectAtIndex:index];
        photoView = [[MmiaPhotoView alloc]initWithFrame:CGRectMake(kPadding+index*(2*kPadding+WIDTH), 0, WIDTH, HEIGHT)];
        photoView.imageUrl = imageUrl;
        photoView.originalFrame = self.originalFrame;
        photoView.photoDelegate = self;
        
        if (index == _curIndex && firstShow) {
            photoView.firstShow = YES;
        }
        else {
            photoView.firstShow = NO;
        }
        photoView.firstSelectedPhoto = index == _firstIndex;
        photoView.tag = kPhotoTag + index;
        [photoView showImage];
    }

    [mainScrollView addSubview:photoView];
    [visiblePhotoArray addObject:photoView];

    [self loadImageNearIndex:index];
}


#pragma mark 加载index附近的图片
- (void)loadImageNearIndex:(NSInteger)index
{
    if (index > 0) {
        NSURL *url = [NSURL URLWithString:[self.imageArray objectAtIndex:index-1]];
        [[SDWebImageManager sharedManager]downloadImageWithURL:url options:SDWebImageLowPriority|SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        }];
    }
    
    if (index < self.imageArray.count - 1) {
        NSURL *url = [NSURL URLWithString:[self.imageArray objectAtIndex:index+1]];
        [[SDWebImageManager sharedManager]downloadImageWithURL:url options:SDWebImageLowPriority|SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        }];
    }
}

#pragma mark index这页是否正在显示
- (BOOL)isShowingPhotoViewAtIndex:(NSUInteger)index {
    for (MmiaPhotoView *photoView in visiblePhotoArray) {
        if (photoView.tag-kPhotoTag == index) {
            return YES;
        }
    }
    return  NO;
}
#pragma mark 循环利用某个view 从队列里面拿
- (MmiaPhotoView *)dequeResuableImageViewWithIndex:(NSUInteger)index {
    NSArray *tempArray = [NSArray arrayWithArray:reusablePhotoArray];
    for (MmiaPhotoView *photoView in tempArray) {
        if (photoView.tag - kPhotoTag == index) {
            [reusablePhotoArray removeObject:photoView];
            return photoView;
        }
    }
    return nil;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    indexlabel.text = [NSString stringWithFormat:@"%tu/%tu",_curIndex+1,_imageArray.count];
    
    MmiaPhotoView *photoView1 = (MmiaPhotoView *)[scrollView viewWithTag:kPhotoTag+_curIndex+1];
    if (photoView1) {
        [photoView1 restoreThePhotoSize];
    }
    MmiaPhotoView *photoView2 = (MmiaPhotoView *)[scrollView viewWithTag:kPhotoTag+_curIndex-1];
    if (photoView2) {
        [photoView2 restoreThePhotoSize];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == mainScrollView) {
        _curIndex = (scrollView.contentOffset.x)/scrollView.frame.size.width;

        [self showPhotos];
        
    }
}

#pragma mark - photoview delegate
- (void)reportPhotoWithTag:(NSInteger)tag {
    if ([self.albumDelegate respondsToSelector:@selector(reportPhotoAlbumWithIndex:)]) {
        [self.albumDelegate reportPhotoAlbumWithIndex:tag-kPhotoTag];
    }
}

- (void)scrollToImageWithTag:(NSInteger)tag {
    if ([self.albumDelegate respondsToSelector:@selector(hidePhotoAlbumWithIndex:)]) {
        [self.albumDelegate hidePhotoAlbumWithIndex:tag - kPhotoTag];
    }
}

#pragma mark - 动画显示隐藏
- (void)show {
    if (_curIndex == 0) {
        [self showPhotos];
    }
    else {
        mainScrollView.contentOffset = CGPointMake(_curIndex*mainScrollView.width, 0);
    }
    // 之后都不是第一次显示了
    firstShow = NO;
}

- (void)hide
{
//    indexlabel.hidden = YES;
//    [UIView animateWithDuration:1 animations:^{
//        mainScrollView.backgroundColor = [UIColor clearColor];
//
//    } completion:^(BOOL finished) {
//        self.alpha = 0;
//
//        [self removeFromSuperview];
//    }];
}
@end

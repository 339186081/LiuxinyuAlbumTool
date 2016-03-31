//
//  MmiaPhotoView.h
//  VIPhotoViewDemo
//
//  Created by liuxinyu on 15/12/22.
//  Copyright © 2015年 vito. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MmiaPhotoViewDelegate <NSObject>

// 举报图片
- (void)reportPhotoWithTag:(NSInteger)tag;

// 消失的时候 滚动到原图位置
- (void)scrollToImageWithTag:(NSInteger)tag;
@end

@interface MmiaPhotoView : UIScrollView

@property (nonatomic, assign) id <MmiaPhotoViewDelegate> photoDelegate;

// 第一张要显示的图片
@property (nonatomic, assign) BOOL firstShow;
// 第一个选中的图片,消失的时候做标记用
@property (nonatomic, assign) BOOL firstSelectedPhoto;

@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong) UIImageView *imageView;


- (void)showImage;
- (void)changeScale:(UITouch *)recognizer;
- (void)restoreThePhotoSize;
@end

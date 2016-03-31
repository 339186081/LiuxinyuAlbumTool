//
//  LXYPhotoView.h
//  HospitalContactor
//
//  Created by lxy on 15/1/4.
//  Copyright (c) 2015年 lxy. All rights reserved.
//  更新返回时 返回原图位置

#import <UIKit/UIKit.h>
#define kPhotoTag 1000

@protocol MmiaPhotoAlbumDelegate <NSObject>

// 举报相册中的某一张图片
- (void)reportPhotoAlbumWithIndex:(NSInteger)index;

// 隐藏相册
- (void)hidePhotoAlbumWithIndex:(NSInteger)index;
@end

@interface MmiaPhotoAlbum : UIView <UIScrollViewDelegate>{}

@property (nonatomic, assign) CGRect originalFrame;

@property (nonatomic, retain) NSArray * imageArray;
@property (nonatomic, assign) NSInteger curIndex;
@property (nonatomic, assign) NSInteger firstIndex;

@property (nonatomic, assign) id <MmiaPhotoAlbumDelegate> albumDelegate;

- (instancetype)initWithArray:(NSArray *)array;

- (void)show;

- (void)hide;
@end

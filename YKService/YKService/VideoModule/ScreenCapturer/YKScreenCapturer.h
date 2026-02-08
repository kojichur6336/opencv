//
//  YKScreenBufferCore.h
//  Created on 2025/9/14
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YKScreenCapturerDelegate <NSObject>

/**
 编码输出数据

 @param data 输出数据
 */
-(void)videoEncodeOutputDataCallback:(NSData *)data;
@end


typedef NS_ENUM(NSInteger, YKVideoQuality) {
    YKVideoQualityLow = 1,         // 低清晰度
    YKVideoQualityMedium = 2,      // 中清晰度 320P
    YKVideoQualityHigh = 3,        // 高清晰度 480P
    YKVideoQualityUltraHigh = 4    // 超高清晰度 720P
};


/// MARK - 屏幕数据流核心
@interface YKScreenCapturer : NSObject
@property(nonatomic, weak) id<YKScreenCapturerDelegate> delegate;//委托

/// 开始视频
/// - Parameters:
///   - type: 类型
///   - width: 宽度
///   - height: 高度
///   - fps: fps
///   - completion: 完成
-(void)startWithQuality:(YKVideoQuality)type videoWidth:(int)width videoHeight:(int)height fps:(float)fps completion:(void (^)(void))completion;


/// 停止
-(void)stopWithCompletion:(void (^)(void))completion;


/// 更新屏幕方向
/// - Parameter newOrientation: 方向
-(void)updateOrientation:(UIInterfaceOrientation)newOrientation;
@end

NS_ASSUME_NONNULL_END

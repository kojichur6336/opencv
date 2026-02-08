//
//  YKServiceScreenBufferController.h
//  Created on 2025/10/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define YKServiceScreenBufferController                        Ac20d23d98208a0e1c0272d13d4202b9695
#define YKServiceScreenBufferControllerDelegate                Bef20dc2s68e16af66368ada4bd2564aa71


@class YKServiceScreenBufferController;
@protocol YKServiceScreenBufferControllerDelegate <NSObject>


/// 编码输出数据
/// - Parameters:
///   - screenBufferController: 屏幕数据流控制器
///   - data: 数据
-(void)serviceScreenBufferController:(YKServiceScreenBufferController *_Nonnull)screenBufferController data:(NSData *_Nonnull)data;

@end


NS_ASSUME_NONNULL_BEGIN

/// MARK - 屏幕数据流控制器
@interface YKServiceScreenBufferController : NSObject
@property(nonatomic, weak) id<YKServiceScreenBufferControllerDelegate> delegate;

/// 更新视频配置
/// - Parameter setting: 视频设置
-(void)updateVideoWithSetting:(NSDictionary *)setting;


/// 更新方向
/// - Parameter orientation: 方向
-(void)updateOrientation:(UIInterfaceOrientation)orientation;


#pragma mark - 视频流开始
-(void)starVideo;


#pragma mark - 停止视频
-(void)stopVideo;
@end

NS_ASSUME_NONNULL_END

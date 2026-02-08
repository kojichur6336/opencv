//
//  YKServiceVideoController.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <UIKit/UIKit.h>
#import "YKServiceIPCController.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKServiceVideoController                        A3265ac2d9be205c17a62e4d041316dd883
#define yksv_updateVideoWithSetting                     Bdc732d7ac50ce31946a445dd9c61000629
#define yksv_connectRemoteVideo                         Cc8d62dae0aac916da7f49e0fbd7d807d2f
#define yksv_port                                       D50cc2sb144aaad5216c7d4f1c9b19fbbc0
#define yksv_videoPort                                  E947a804f72330b061e6182d6143591d97f


/// MARK - 视频控制器
@interface YKServiceVideoController : NSObject
@property(nonatomic, assign) UInt16 yksv_videoPort;//视频端口
@property(nonatomic, assign) UIInterfaceOrientation orientation;//屏幕方向

/// 初始化
/// - Parameter iPCController: 进程通讯控制器
-(instancetype)initWithIPCController:(YKServiceIPCController *)iPCController;


/// 更新视频设置
/// - Parameter setting: 视频设置
-(void)yksv_updateVideoWithSetting:(NSDictionary *)setting;


/// 连接远程视频
/// - Parameters:
///   - ip: IP
///   - port: 端口
-(void)yksv_connectRemoteVideo:(NSString *)ip yksv_port:(int)port;
@end

NS_ASSUME_NONNULL_END

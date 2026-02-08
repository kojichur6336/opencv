//
//  YKServiceRemoteController.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <UIKit/UIKit.h>
#import "YKServiceIPCController.h"

NS_ASSUME_NONNULL_BEGIN

#define YKServiceRemoteController                              A07f4b82cbc7ef3e18261016820c3fe8a64
#define YKServiceRemoteControllerDelegate                      B1a3ec2d39020a147a5e0620a8218da5419
#define yksr_serviceRemoteController                           Ce733e934e982w31d373c9b6d46777df201
#define yksr_videoSettings                                     D90262a74eadaffc0ced8dc2cc1d48f8e2d
#define yksr_videoPortForServiceRemoteController               E7c649b318fd2eb8f2bb3a0d3db3eb0e2fd
#define yksr_videoIP                                           Ff75979d9f423d2429ac19a0ffd39493970
#define yksr_port                                              G46108a8623a07231d9e7f7b69baf009291
 

@class YKServiceRemoteController;
@protocol YKServiceRemoteControllerDelegate <NSObject>

/// 切换视频清晰度
/// - Parameters:
///   - vc: 控制器
///   - setting: 设置
-(void)yksr_serviceRemoteController:(YKServiceRemoteController *)vc yksr_videoSettings:(NSDictionary *)setting;


/// 获取视频的端口
/// - Parameter vc:控制器
-(UInt16)yksr_videoPortForServiceRemoteController:(YKServiceRemoteController *)vc;


/// 远程视频连接
/// - Parameters:
///   - vc: 控制器
///   - ip: IP
///   - port: 端口
-(void)yksr_serviceRemoteController:(YKServiceRemoteController *)vc yksr_videoIP:(NSString *)ip yksr_port:(int)port;
@end

/// MARK - 远程控制器
@interface YKServiceRemoteController : NSObject
@property(nonatomic, assign) UIInterfaceOrientation orientation;//屏幕方向
@property(nonatomic, weak) id<YKServiceRemoteControllerDelegate> delegate;//委托


/// 初始化
/// - Parameter iPCController: 进程通讯控制器
-(instancetype)initWithIPCController:(YKServiceIPCController *)iPCController;
@end

NS_ASSUME_NONNULL_END

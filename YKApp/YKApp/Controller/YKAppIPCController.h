//
//  YKAppIPCController.h
//  YKApp
//
//  Created by liuxiaobin on 2025/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKAppIPCController          A3659a113618e5e0fa519c1cba0176e13d1
#define yk_getDeviceInfo            B4c0096128e4634ee5abb2699922113644a
#define yk_homeScreen               C85279ed52x916ffc3e187134813bc01b14
#define yk_reStart                  Dd382a18693a2xf212b2b8b412bb8c689bb
#define yk_openSetting              E31fc0f124f644479263072c33518d86f10
#define yk_scanQrcode               F70eb8aed14577102435ab2e8a2333xbac3
#define yk_isServiceEnabled         G08e8cf9bdbcc2x419a6b666c6a08705b23


@class YKAppIPCController;
@protocol YKAppIPCControllerDelegate <NSObject>


/// 信息
/// - Parameters:
///   - controller: 控制器
///   - deviceInfo: 设备信息
-(void)appIPCController:(YKAppIPCController *)controller deviceInfo:(NSDictionary *)deviceInfo;



/// 扫描二维码回执
/// - Parameters:
///   - controller: 控制器
///   - msg: 回执消息
-(void)appIPCController:(YKAppIPCController *)controller qrcodeMsg:(NSString *)msg;



/// 请求服务超时
/// - Parameters:
///   - controller: 控制
///   - msg: 消息
-(void)appIPCController:(YKAppIPCController *)controller firstTxtFileName:(NSString *)firstTxtFileName errorMsg:(NSString *)msg;
@end


/// MARK - IPC控制器
@interface YKAppIPCController : NSObject
@property(nonatomic, weak) id<YKAppIPCControllerDelegate> delegate;//委托


/// 获取设备信息
-(void)yk_getDeviceInfo;


/// 首屏
-(void)yk_homeScreen;


/// 重启服务
-(void)yk_reStart;


/// 打开设置页面
-(void)yk_openSetting;


/// 扫描二维码识别
/// - Parameter qrcode: 二维码
-(void)yk_scanQrcode:(NSString *)qrcode;


/// 设置服务是否启用
/// - Parameter isServiceEnabled: 是否启用
-(void)yk_isServiceEnabled:(BOOL)isServiceEnabled;
@end

NS_ASSUME_NONNULL_END

//
//  YKServiceIPCController.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKServiceIPCController                               Ac3d257d6aeae024b860d645974f131f683
#define YKServiceIPCControllerDelegate                       B8362s15e0c102a352f6a7ac84caf8fb900
#define ykipc_serviceIPCController                           Cb4046da7c347863dd436120c6e207eb309
#define ykipc_didCopyContent                                 D5ca2b2sfb81ed17994e246ac15d5ee8d4b
#define ykipc_type                                           Ec3007e1e9f92s046bf7890a619966fccb2
#define ykipc_appName                                        Faddaz898a7e5080a3de08cc09c4d0c84fa
#define ykipc_bid                                            G5449d65122se4a35427f3a5f7784921bad
#define ykipc_serviceIPCControllerConnectedServices          H3ba2d7d9e3dee1724cdd5efb2890c0c7c2
#define ykipc_qrCode                                         Ia4b4a2daaaba4033a14e8ede5e0e347eca
#define ykipc_isChineseInput                                 Ja1bda0632s3fdbf0ca6b995cd7c0737b6e
#define ykipc_isServiceEnabled                               K9c4d0282s136237d9cb075d0c22d174569
#define ykipc_serviceIPCControllerServiceEnabled             Lc5e785ffd92s6142942a5c6f286ab8805f
#define ykipc_springBoardMsg                                 Mb9dda212fdab7a3f60704e17307eb196e4
#define ykipc_choicyMsg                                      N9d7a51b37ce12sb1fca22b51232522013f
#define ykipc_showLogsMessage                                Od8bdcbd730a09386e915c01f22s899a4c5
#define ykipc_installDeb                                     P6857b80b2xa23a3dc07d0e97257d437cf4
#define yjipc_uninstallDeb                                   Q9c42389048e0931cbbcde75453a48f21b3
#define ykipc_uuid                                           Q84492d77eea295d9a187d2fe18d966fa22
#define ykipc_screenUnlock                                   Ra012399c5168c816dde11e974806cbb0bb
#define ykipc_getFrontBid                                    S342dabe09be82b52a3fc7e0f8d33a9e65d
#define ykipc_setDeviceName                                  T4dc7029418ac8a8811bc4174084f11e122
#define ykipc_homeScreen                                     U7e58ba1308f021883c7d03d71de4d7714a
#define ykipc_killAllApp                                     V4fb76d007c2dc925d77c243be3469bface
#define ykipc_showCenterController                           We7aac984cc1e4fafe6e2489f2e07c46d23
#define ykipc_updateConnect                                  X246cd231d30cfb50ed24bb2f933d98b852
#define ykipc_setWifiEnable                                  Za4ffc23664347d65fb1d963eae4bb87fb7
#define ykipc_setCellularDataEnable                          A44ea4459dxgf802131373145419df518a3
#define ykipc_getAppDataPathWithType                         C4c26cd2d5c6a9ec94511e48d6b2753a235
#define ykipc_identifier                                     Daa8882357c153dec39900629c98e61b662
#define ykipc_airPlaySwitch                                  E6029213a739535ae5e7a6d3016ae766e2b
#define ykipc_airPlayName                                    F314be0c23ff14d0f588ae17e30bf2e66da
#define ykipc_audioPlaySwitch                                Gfbc33s8a03b05701094ae4f6d590f6ab1b
#define ykipc_deviceName                                     Hf5067c8938238cccf6f5f67c2df69df283
#define ykipc_scanQrcodeReceipt                              I74b9e3315fxed9b4ee9fc60026c2fb2dda
#define ykipc_getAudioPort                                   J2e87092fcc51a93dd2f0eff7959dff626e
#define ykipc_connectAudioWithIP                             K5ec446afc1103v25dd68329bd79ec57103
#define ykipc_port                                           Lc812d86c0f5681aa751929b745f97c8751
#define ykipc_startRecordAnimation                           M640797027ccefdd3f67d7d8c42f3222d5d
#define ykipc_stopRecordAnimation                            O4f5232dcf397deaed3d55a9f00fa8d71ca
#define ykipc_deviceNameChanged                              P699233fa12ed2fd90825ed0afb770c8f2d
#define ykipc_killWithBid                                    Q34469923caa1af40b8fb13363b6d5f5ba7
#define ykipc_getClipboardContentWaiting                     Rebc62saceda42871f826b0fd0dfb19dde1
#define ykipc_isScreenLocked                                 Sfcd1e28e7c7189f4bdae59656c0a7ce236

@class YKServiceIPCController;
@protocol YKServiceIPCControllerDelegate <NSObject>

/// 复制文本通知
/// - Parameters:
///   - serviceIPCController: 控制器
///   - content: 内容
///   - type: 类型
///   - appName:来源那个App
///   - bid: 包名
-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_didCopyContent:(NSString *)content ykipc_type:(int)type ykipc_appName:(NSString *)appName ykipc_bid:(NSString *)bid;


/// 获取已连接的服务数组
/// - Parameter serviceIPCController: serviceIPCController
-(NSArray *)ykipc_serviceIPCControllerConnectedServices:(YKServiceIPCController *)serviceIPCController;



/// 二维码扫描连接
/// - Parameters:
///   - vc: 控制器
///   - qrCode: 二维码
-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_qrCode:(NSString *)qrCode;



/// 启动服务开关切换
/// - Parameters:
///   - serviceIPCController: 控制器
///   - isServiceEnabled: 是否启用服务
-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_isServiceEnabled:(BOOL)isServiceEnabled;



/// 获取服务是否启用
/// - Parameter serviceIPCController: 控制器
-(BOOL)ykipc_serviceIPCControllerServiceEnabled:(YKServiceIPCController *)serviceIPCController;



/// 设备名称更新
/// - Parameters:
///   - serviceIPCController:控制器
///   - deviceName: 设备名称更新
-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_deviceNameChanged:(NSString *)deviceName;
@end


/// MARK - 服务进程通讯
@interface YKServiceIPCController : NSObject
@property(nonatomic, copy) NSString *ykipc_springBoardMsg;//Springboard重启提示
@property(nonatomic, copy) NSString *ykipc_choicyMsg ;//Choicy屏蔽提示
@property(nonatomic, weak) id<YKServiceIPCControllerDelegate> delegate;


/// 显示日志消息
/// - Parameter message:消息
-(void)ykipc_showLogsMessage:(NSString *)message;


/// 安装Deb回执
/// - Parameter path: 路径
-(void)ykipc_installDeb:(NSString *)path completion:(void (^)(BOOL result, NSString *debMsg))completion;



/// 卸载deb
/// - Parameters:
///   - bid: 包名
///   - completion: 完成
-(void)yjipc_uninstallDeb:(NSString *)bid completion:(void (^)(BOOL result, NSString *debMsg))completion;



/// 获取设备唯一标识
-(NSString *)ykipc_uuid;


/// 屏幕解锁
-(void)ykipc_screenUnlock;


/// 获取前台执行的App
-(NSString *)ykipc_getFrontBid;


/// 修改设备名称
/// - Parameter name: 名称
-(void)ykipc_setDeviceName:(NSString *)name;


/// 回到首页
-(void)ykipc_homeScreen;


/// 关闭所有后台App
-(void)ykipc_killAllApp;


/// 显示控制中心
-(void)ykipc_showCenterController;


/// 更新App连接状态
-(void)ykipc_updateConnect;


/// 设置WIFI是否开关
/// - Parameter enable: true-启用 false-关闭
-(void)ykipc_setWifiEnable:(BOOL)enable;



/// 设置蜂窝开关
/// - Parameter enable: true-启用 false-关闭
-(void)ykipc_setCellularDataEnable:(BOOL)enable;



/// 获取App数据类型
/// - Parameters:
///   - type: 类型(1:沙盒路径 2:安装包路径 3:共享数据路径)
///   - identifier: id
-(NSString *)ykipc_getAppDataPathWithType:(int)type ykipc_identifier:(NSString *)identifier;



/// AirPlay切换
/// - Parameters:
///   - isOpen: 是否开
///   - airPlayName: airPlay名称
-(void)ykipc_airPlaySwitch:(BOOL)isOpen ykipc_airPlayName:(NSString *)airPlayName;


/// 音频播放
/// - Parameters:
///   - isOpen: 是否打开
///   - deviceName: 设备名称
-(void)ykipc_audioPlaySwitch:(BOOL)isOpen ykipc_deviceName:(NSString *)deviceName;



/// 二维码链接扫描回执
/// - Parameter msg: 消息
-(void)ykipc_scanQrcodeReceipt:(NSString *)msg;



/// 获取音频端口
/// - Parameter completion: 获取音频端口
-(void)ykipc_getAudioPort:(void (^)(BOOL result, UInt16 port))completion;


/// 连接音频
/// - Parameters:
///   - ip: IP地址
///   - port: 端口
///   - completion: 完成连接成功或者失败
-(void)ykipc_connectAudioWithIP:(NSString *)ip ykipc_port:(UInt16)port completion:(void (^)(BOOL result, NSString *msg))completion;



/// 开始录制倒计时动画
/// - Parameter completion: 完成回调
-(void)ykipc_startRecordAnimation:(void (^)(void))completion;


/// 停止录制动画
-(void)ykipc_stopRecordAnimation;


/// 关闭指定Bid
/// - Parameter bid: 包名
-(void)ykipc_killWithBid:(NSString *)bid;


/// 获取剪切板信息
-(NSDictionary *)ykipc_getClipboardContentWaiting:(BOOL)shouldWait;


/// 是否锁定屏幕(-1:未获取到 1:锁屏 2:未锁屏)
-(int)ykipc_isScreenLocked;
@end

NS_ASSUME_NONNULL_END

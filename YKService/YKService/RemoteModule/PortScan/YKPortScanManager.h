//
//  YKPortScanManager.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <Foundation/Foundation.h>
#import <YKSocket/GCDAsyncSocket.h>

NS_ASSUME_NONNULL_BEGIN


#define YKPortScanManager                            A5fd58362ddd6636789f8a633cf44221486
#define YKPortScanManagerDelegate                    Bf78a766e7d6733712d5adefe2808df726b
#define ykpsm_portScanManager                        C9cc423972b98cd3896157182b518d9922b
#define ykpsm_ip                                     D398846a723348fd3653e746dfb43900705
#define ykpsm_port                                   E34bec80b121acd59923dea013015b29b61
#define ykpsm_remoteDeviceName                       Fcc4f7ee536b23f213ce92e940a50f4d248

@class YKPortScanManager;
@protocol YKPortScanManagerDelegate <NSObject>

/// WIFI局域网扫描连接请求
/// - Parameters:
///   - scan: 扫描对象
///   - ip: ip地址
///   - port: 端口
///   - remoteDeviceName: 远端设备名称
///   - isScan: 是否扫描
-(void)ykpsm_portScanManager:(YKPortScanManager *)scan ykpsm_ip:(NSString *)ip ykpsm_port:(uint16_t)port ykpsm_remoteDeviceName:(NSString *)remoteDeviceName;
@end


/// MARK - 端口扫描管理类
@interface YKPortScanManager : NSObject


/// 初始化
/// - Parameters:
///   - port: 端口
///   - delegate: 委托
-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKPortScanManagerDelegate>) delegate;



/// 在指定端口上启动 TCP 套接字监听器
/// - Parameter error: 指向实际启动错误描述的别名，如果套接字已启动并正在监听，则为 nil
-(BOOL)startWithError:(NSError **)error;


/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

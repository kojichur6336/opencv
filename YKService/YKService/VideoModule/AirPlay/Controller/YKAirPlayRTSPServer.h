//
//  YKAirPlayHTTPService.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/19.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKAirPlayRTSPServer;
@protocol YKAirPlayRTSPServerDelegate <NSObject>


/// 获取AirPlay RTSP Server的公钥
/// - Parameter service: 当前的 YKAirPlayRTSPServer 服务实例
/// - Returns: 公钥数据
-(NSData *)airPlayRTSPServerGetPairSetupPublicKey;


/// 验证配对签名1
/// - Parameters:
///   - service: 当前的 YKAirPlayRTSPServer 服务实例
///   - pairVerifySign1: 配对验证签名数据
/// - Returns: 验证后的数据
-(NSData *)airPlayRTSPServer:(YKAirPlayRTSPServer *)service pairVerifySign1:(NSData *)pairVerifySign1;


/// 验证配对签名
/// - Parameters:
///   - service: 当前的 YKAirPlayRTSPServer 服务实例
///   - pairVerifySign2: 配对验证签名数据
/// - Returns: 验证后成功与失败
-(BOOL)airPlayRTSPServer:(YKAirPlayRTSPServer *)service pairVerifySign2:(NSData *)pairVerifySign2;



/// 解密SETUP
/// - Parameters:
///   - service:当前的 YKAirPlayRTSPServer 服务实例
///   - appleFairPlayDRM: Apple FairPlay DRM 加密
///   - ekey: eKey
-(void)airPlayRTSPServer:(YKAirPlayRTSPServer *)service appleFairPlayDRM:(NSData *)appleFairPlayDRM ekey:(NSData *)ekey;


/// 传出连接ID
/// - Parameters:
///   - service: 当前的 YKAirPlayRTSPServer 服务实例
///   - streamConnectionID: 连接ID
-(BOOL)airPlayRTSPServer:(YKAirPlayRTSPServer *)service streamConnectionID:(uint64_t)streamConnectionID;


/// 获取镜像端口
-(int)airPlayRTSPServerGetMirrorPort;


/// 镜像关闭
/// - Parameter service: 服务关闭
-(void)airPlayRTSPServerStop:(YKAirPlayRTSPServer *)service;


/// 音频控制端口
-(NSDictionary *)airPlayRTSPServerGetAudioPort;
@end



/// MARK - 开启AirPlay RTSP 服务
@interface YKAirPlayRTSPServer : NSObject


/// 初始化
/// - Parameters:
///   - delegate: 委托
-(instancetype)initWithDelegate:(id<YKAirPlayRTSPServerDelegate>)delegate;



/// 在指定端口上启动 TCP 套接字监听器
/// - Parameter error: 指向实际启动错误描述的别名，如果套接字已启动并正在监听，则为 nil
-(int)startWithError:(NSError **)error;


/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

//
//  YKClientSocket.h
//  Created on 2025/9/16
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//


#import "YKConnectionContext.h"
#import <Foundation/Foundation.h>
#import "YKClientDeviceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

#define YKClientSocket                                 Ab7c3ecd32059ee364ddda587bfa74c5123
#define YKClientSocketDelegate                         B61bd8a2299774123ce43ceb6819e1c484e
#define ykcs_clientSocket                              Cd4190a333d07f4709b151b272cac1a619c
#define ykcs_didAddDevice                              Df3aa03c302327c447b96917796563219e5
#define ykcs_device                                    E928660db395328ec9e5d8ceb8b78fb31bc
#define ykcs_received                                  F41d5e2de20ecc213cad98139dde6b8d095
#define ykcs_closeDevice                               Gee20e46c6323ac656d2301aaf6842e030f
#define ykcs_scanQrCodeError                           H6331dc521a721d573047e9444b94176595
#define ykcs_startWithServerIp                         Id4c5279aa21a2bfef1d373fbc1b8903807
#define ykcs_serverPort                                Jdb102256d6223a774b6b760e9672e5c543
#define ykcs_remoteDeviceName                          K5aabe9972300076d30ef1011e4d0980732
#define ykcs_connectionContext                         L1531a82177154550b8695b456b49714c39
#define ykcs_error                                     M8b021a25dx592612a69c108222c6d6cc51
#define ykcs_sendData                                  Ofca2303ee7e02b632dcbbed001d81aee0e
#define ykcs_getConnectedServices                      P7422315846b0aaf79fdad1d76250f4b73c
#define ykcs_start                                     Qa44427ce052d14f09d50ab40f9070d8978
#define ykcs_stop                                      Rda821dc629324b9cd71d9530b4f899101c



@class YKClientSocket;
@protocol YKClientSocketDelegate <NSObject>

/// 有新的客户端连接进来
/// @param clientSocket 当前管理的客户端Socket对象
/// @param device 新连接的设备（USB 或 WiFi）
-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_didAddDevice:(id<YKClientDeviceProtocol>)device;


/// 收到回执
/// - Parameters:
///   - clientSocket:连接对象
///   - device: 设备
///   - data: 收到回执数据
-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_device:(id<YKClientDeviceProtocol>)device ykcs_received:(NSDictionary *)data;



/// 收到关闭
/// @param clientSocket 连接对象
/// @param device 设备
-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_closeDevice:(id<YKClientDeviceProtocol>)device;



/// 扫描二维码连接失败
/// @param clientSocket 连接对象
/// @param msg 消息
-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_scanQrCodeError:(NSString *)msg;
@end


/// MARK - 客户端Socket
@interface YKClientSocket : NSObject

/// 初始化
/// - Parameters:
///   - model: 实体
///   - delegate: 委托
-(instancetype)initWithDelegate:(id<YKClientSocketDelegate>)delegate;


/// 开始连接
/// - Parameters:
///   - serverIp: 服务端ip
///   - port: 端口
///   - remoteDeviceName: 设备名称
///   - connectionContext: 扫码类型(0:默认不是 1:局域网 2:广域网)
///   - error: 错误
-(BOOL)ykcs_startWithServerIp:(NSString *)serverIp ykcs_serverPort:(uint16_t)port ykcs_remoteDeviceName:(NSString *)remoteDeviceName  ykcs_connectionContext:(YKConnectionContext *)context ykcs_error:(NSError **)error;


/// 发送数据针对唯一标识
/// - Parameters:
///   - data: 数据
///   - identity: 唯一标识
-(void)ykcs_sendData:(NSData *)data ykcs_device:(nullable id<YKClientDeviceProtocol>)device;


/// 发送数据给所有连接者
/// - Parameter data: 数据
-(void)ykcs_sendData:(NSData *)data;


/// 获取连接服务信息
-(NSArray *)ykcs_getConnectedServices;


/// 开始
-(void)ykcs_start;


/// 停止所有的客户端连接
-(void)ykcs_stop;
@end

NS_ASSUME_NONNULL_END

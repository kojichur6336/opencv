//
//  YKClientSocketWIFI.h
//  Created on 2025/9/16
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKConnectionContext.h"
#import "YKClientDeviceProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKClientSocketWIFI;
@protocol YKClientSocketWIFIDelegate <NSObject>

/// 已连接
/// - Parameters:
///   - socket: socket
///   - host: host
///   - port: port
-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket didConnectToHost:(NSString *)host port:(uint16_t)port;


/// 断开连接
/// - Parameters:
///   - socket: socket
///   - err: err
-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket withError:(NSError *)err;


/// 收到数据
/// - Parameters:
///   - socket: socket
///   - data: 数据
///   - tag: 标签
-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket didReadData:(NSData *)data withTag:(long)tag;
@end


/// MARK - WIFI Socket连接
@interface YKClientSocketWIFI : NSObject<YKClientDeviceProtocol>
@property(nonatomic, readonly) NSString *ip;//ip地址
@property(nonatomic, readonly) uint16_t port;//端口
@property(nonatomic, readonly) NSString *identifier;//连接对方的IP地址+端口
@property(nonatomic, copy) NSString *remoteDeviceName;//远程设备名称
@property(nonatomic, strong) YKConnectionContext * context;//连接上下文
@property(nonatomic, readonly) BOOL isConnected;//是否已连接


/// 初始化
/// - Parameters:
///   - delegate: 回调
-(instancetype)initWithDelegate:(id<YKClientSocketWIFIDelegate>)delegate;


/// 开始连接
/// - Parameters:
///   - serverIp: 服务器端IP
///   - port: 服务端端口
///   - error: 错误
-(BOOL)startWithServerIp:(NSString *)serverIp serverPort:(uint16_t)port remoteDeviceName:(NSString *)remoteDeviceName  error:(NSError **)error;


/**
 如果套接字正在运行，则停止套接字
 */
-(void)stop;


/// 从 socket 中读取指定长度的数据，并设置超时时间和标签。
///
/// @param length 要读取的数据长度
/// @param timeout 超时时间，单位为秒
/// @param tag 标签，用于标识此次读取操作
-(void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;


/// 发送数据
/// @param data 数据
-(void)sendData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END

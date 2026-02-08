//
//  YKClientSocketUSB.h
//  Created on 2025/10/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKClientDeviceProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKClientSocketUSB;
@protocol YKClientSocketUSBDelegate <NSObject>

/// 已连接
/// - Parameters:
///   - socket: socket
///   - host: host
///   - port: port
-(void)clientSocketUSB:(YKClientSocketUSB *)socket didConnectToHost:(NSString *)host port:(uint16_t)port;


/// 断开连接
/// - Parameters:
///   - socket: socket
///   - err: err
-(void)clientSocketUSB:(YKClientSocketUSB *)socket withError:(NSError *)err;


/// 收到数据
/// - Parameters:
///   - socket: socket
///   - data: 数据
///   - tag: 标签
-(void)clientSocketUSB:(YKClientSocketUSB *)socket didReadData:(NSData *)data withTag:(long)tag;
@end


/// MARK - 客户端USBSocket
@interface YKClientSocketUSB : NSObject<YKClientDeviceProtocol>
@property(nonatomic, readonly) NSString *ip;//ip地址
@property(nonatomic, readonly) uint16_t port;//端口
@property(nonatomic, readonly) NSString *identifier;//唯一标识
@property(nonatomic, copy) NSString *remoteDeviceName;//远程设备名称
@property(nonatomic, readonly) BOOL isConnected;//是否连接


/// 初始化
/// - Parameters:
///   - port: 端口
///   - delegate: 委托
-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKClientSocketUSBDelegate>) delegate;


/// 在指定端口上启动 TCP 套接字监听器
/// - Parameter error: 指向实际启动错误描述的别名，如果套接字已启动并正在监听，则为 nil
-(BOOL)startWithError:(NSError **)error;


/// 停止
-(void)stop;


/// 从 socket 中读取指定长度的数据，并设置超时时间和标签。
///
/// @param length 要读取的数据长度
/// @param timeout 超时时间，单位为秒
/// @param tag 标签，用于标识此次读取操作
-(void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;

/// 发送数据
/// - Parameter data: 数据
-(void)sendData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END

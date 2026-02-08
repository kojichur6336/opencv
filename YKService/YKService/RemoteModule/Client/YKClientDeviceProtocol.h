//
//  YKClientDeviceProtocol.h
//  Created on 2025/10/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 设备协议
@protocol YKClientDeviceProtocol <NSObject>
@property(nonatomic, readonly) NSString *ip;//ip地址
@property(nonatomic, readonly) uint16_t port;//端口
@property(nonatomic, readonly) NSString *identifier;// 唯一标识属性
@property(nonatomic, copy) NSString *remoteDeviceName;//远程设备名称
@property(nonatomic, readonly) BOOL isConnected;//是否已连接

/// 从 socket 中读取指定长度的数据，并设置超时时间和标签。
///
/// @param length 要读取的数据长度
/// @param timeout 超时时间，单位为秒
/// @param tag 标签，用于标识此次读取操作
-(void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;

// 发送数据方法
-(void)sendData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END

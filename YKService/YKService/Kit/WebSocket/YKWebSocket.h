//
//  YKNativeWebSocket.h
//  Created on 2025/11/30
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

@class YKWebSocket;

/// MARK - WebSocket 的代理协议
@protocol YKWebSocketDelegate <NSObject>


/// 当 WebSocket 连接成功时调用
/// - Parameter webSocket: YKWebSocket
-(void)webSocketDidConnect:(YKWebSocket *_Nonnull)webSocket;


/// 当 WebSocket 断开连接时调用
/// - Parameter webSocket: YKWebSocket
-(void)webSocketDidDisconnect:(YKWebSocket *_Nonnull)webSocket;


/// 当 WebSocket 接收到数据时调用
/// - Parameters:
///   - webSocket: YKWebSocket
///   - data: NSData
-(void)webSocket:(YKWebSocket *_Nonnull)webSocket didReceiveData:(NSData *_Nonnull)data;



/// 当WebSocket 接受到文本数据时调用
/// - Parameters:
///   - webSocket: YKWebSocket
///   - text: 文本数据
-(void)webSocket:(YKWebSocket *_Nonnull)webSocket didReceiveText:(NSString *_Nonnull)text;
@end


NS_ASSUME_NONNULL_BEGIN

/// MARK - WebSocket
@interface YKWebSocket : NSObject
@property (nonatomic, weak) id<YKWebSocketDelegate> delegate;//委托

/// 初始化
/// - Parameter url: 地址
-(instancetype)initWithURL:(NSURL *)url;


/// 连接 WebSocket 的方法
-(void)connect;


/// 断开连接
-(void)disconnect;


/// 发送数据的方法
/// - Parameter data: 数据
-(void)sendData:(NSData *)data;


/// 发送文本数据
/// - Parameter text: 文本
-(void)sendText:(NSString *)text;


/// 开始心跳
-(void)startHeartbeat;
@end

NS_ASSUME_NONNULL_END

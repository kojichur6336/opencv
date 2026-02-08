//
//  YKCFMessagePortRemote.h
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YKCFMessagePortErrorCode) {
    YKCFMessagePortErrorSuccess = 1000,         // 成功
    YKCFMessagePortErrorRemotePortUnavailable,  // 远程端口未初始化或不可用
    YKCFMessagePortErrorSerializeFailed,        // 数据序列化失败
    YKCFMessagePortErrorSendTimeout,            // 发送超时
    YKCFMessagePortErrorReceiveTimeout,         // 回复超时
    YKCFMessagePortErrorRemotePortInvalid,      // 远程端口失效
    YKCFMessagePortErrorUnknown = -9999         // 未知错误
};

/// MARK - 返回结构对象
@interface YKCFMessagePortSyncResult : NSObject
@property(nonatomic, assign) YKCFMessagePortErrorCode errorCode;
@property(nonatomic, strong, nullable) NSDictionary *replyData;
+ (instancetype)resultWithError:(YKCFMessagePortErrorCode)errorCode reply:(nullable NSDictionary *)reply;
@end


/// 异步消息回调，返回回复数据和错误码
typedef void(^YKCFMessagePortAsyncReplyHandler)(NSDictionary * _Nullable replyData, YKCFMessagePortErrorCode errorCode);



/// MARK - 远程端口（客户端)
@interface YKCFMessagePortRemote : NSObject
@property(nonatomic, assign) NSTimeInterval sendTimeout;//发送超时
@property(nonatomic, assign) NSTimeInterval rcvTimeout;//回执超时


/// 初始化远程端口（客户端），指定端口名称
/// @param name 端口名称
-(instancetype)initWithName:(NSString *)name;


/// 发送消息
/// @param cmd  命令
-(YKCFMessagePortErrorCode)sendMessage:(NSInteger)cmd;


/// 发送消息
/// @param message 消息
/// @param cmd 命令
-(YKCFMessagePortErrorCode)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd;


/// 发送消息
/// @param message 消息
/// @param cmd 命令
/// @param retryCount 重试次数
-(YKCFMessagePortErrorCode)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd maxRetries:(NSUInteger)retryCount;


/// 发送消息带返回值
/// @param message 消息
/// @param cmd 命令
/// @param retryCount 重试次数
/// @param callbackQueue 回调队列
/// @param handler 异步回调结果
-(void)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd maxRetries:(NSUInteger)retryCount  resultHandlerQueue:(dispatch_queue_t)callbackQueue replyHandler:(YKCFMessagePortAsyncReplyHandler)handler;



/// 同步发送消息，阻塞等待回复
/// @param cmd 消息标识（命令ID）
/// @return 服务器返回的回复数据，如果超时或失败返回 nil
-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSInteger)cmd;


/// 同步发送消息，阻塞等待回复
/// @param message 要发送的消息数据（NSData）
/// @param cmd 消息标识（命令ID）
/// @return 服务器返回的回复数据，如果超时或失败返回 nil
-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSDictionary *)message cmd:(NSInteger)cmd;



/// 同步发送消息，阻塞等待回复，支持指定最大重试次数
/// @param message 要发送的消息数据（NSData）
/// @param cmd 消息标识（命令ID）
/// @param retryCount 最大重试次数，发送失败时会自动重试，直到达到次数或成功
/// @return 服务器返回的回复数据，如果超时或失败返回 nil
-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSDictionary *)message cmd:(NSInteger)cmd maxRetries:(NSUInteger)retryCount;



/// 关闭远程端口，释放资源
-(void)invalidate;
@end

NS_ASSUME_NONNULL_END

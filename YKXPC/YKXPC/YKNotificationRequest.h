//
//  YKNotificationRequest.h
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// 通知完成回调块类型定义
/// @param cmd 命令码，用于标识具体的操作或消息类型
/// @param replyID 回复标识符，用于关联请求与回复
/// @param data 消息内容数据，以字典形式传递具体信息
typedef void (^YKNotificationCompletionHandler)(NSInteger cmd, NSString *replyID, NSDictionary *data);


/// MARK - 通知请求
@interface YKNotificationRequest : NSObject


/// 单例
+(instancetype)shared;

/// 添加通知监听
/// - Parameters:
///   - observer: 可观察者
///   - port: 端口
///   - completion: 完成处理回调
-(void)addNotificationWithObserver:(id)observer port:(NSString *)port completion:(YKNotificationCompletionHandler)completion;


/// 发送通知
/// - Parameters:
///   - port: 端口
///   - cmd: 命令
-(void)postWithPort:(NSString *)port cmd:(NSInteger)cmd;


/// 发送通知
/// - Parameters:
///   - port: 端口
///   - data: 数据
-(void)postWithPort:(NSString *)port data:(NSDictionary *)data;


/// 发送通知
/// - Parameters:
///   - port: 端口
///   - cmd: 命令
///   - data: 数据
-(void)postWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data;


/// 发送请求(同步会锁住当前线程 默认超时1小时)
/// - Parameters:
///   - port: 端口
///   - cmd: 命令
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd;


/// 发送请求(同步会锁住当前线程 默认超时1小时)
/// - Parameters:
///   - port: 端口
///   - cmd: 命令
///   - data: 数据
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data;


/// 发送请求(同步会锁住当前线程)
/// - Parameters:
///   - port: 端口
///   - cmd: 命令
///   - data: 数据
///   - timeout: 超时
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data timeout:(NSTimeInterval)timeout;


/// 移除端口
/// - Parameters:
///   - port: 端口
-(void)removeNotificationForPort:(NSString *)port;
@end

NS_ASSUME_NONNULL_END

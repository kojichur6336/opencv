//
//  YKCFMessagePortLocal.h
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 同步消息处理回调类型定义
///
/// @param cmd   接收到的消息ID，用于区分不同类型的消息
/// @param msgData 接收到的消息数据，可能为 nil
///
/// @return 返回对消息的响应数据，类型为 NSDictionary*，可为 nil 表示不需要回复。
///         注意，返回值只包含回复数据本身，不需要包含 cmd，
///         因为 msgid 仅用作请求的消息标识，回复直接用数据即可。
typedef NSDictionary* _Nullable (^YKCFMessagePortSyncHandler)(int cmd, NSDictionary * _Nullable msgData);


/// MARK - 进程通讯本地服务端
@interface YKCFMessagePortLocal : NSObject


/// 初始化本地端口（服务端），指定端口名和同步消息处理回调
/// @param name 端口名称
/// @param runLoop  运行
/// @param syncHandler 同步消息处理回调
-(instancetype)initWithName:(NSString *)name runLoop:(CFRunLoopRef)runLoop syncHandler:(YKCFMessagePortSyncHandler)syncHandler;

/// 关闭端口，释放资源
-(void)invalidate;
@end

NS_ASSUME_NONNULL_END

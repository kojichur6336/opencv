//
//  YKAirPlayMirror.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class YKAirPlayMirror;
@protocol YKAirPlayMirrorDelegate <NSObject>


/// 接收到视频流数据
/// - Parameters:
///   - airPlayMirror: 镜像对象
///   - nPayloadType: 数据内容类型 (1: 没加密 0:是加密)
///   - data: 视频流数据
-(void)airPlayMirror:(YKAirPlayMirror *)airPlayMirror nPayloadType:(int)nPayloadType data:(NSData *)data;
@end


/// MARK - 处理AirPlay镜像数据
@interface YKAirPlayMirror : NSObject

/// 初始化屏幕镜像
/// - Parameter delegate:委托
-(instancetype)initWithDelegate:(id<YKAirPlayMirrorDelegate>)delegate;


/// 在指定端口上启动 TCP 套接字监听器
/// - Parameter error: 指向实际启动错误描述的别名，如果套接字已启动并正在监听，则为 nil
-(int)startWithError:(NSError **)error;


/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

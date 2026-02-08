//
//  YKPortScanUDP.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKPortScanWIFI                               Af136323a84355608bd30d9928fa4dca8ef
#define YKPortScanWIFIDelegate                       Bd0288ac23da9a65be42fd9b73c8e9448c1
#define ykpswifi_didReceiveUDPMessageWithLogin       Ccc2b3dabdbe63c397c746f8fcb84df9023
#define ykpswifi_data                                D735523ecf63707d77f54facc4163fbd394


/// MARK - YKPortScanWIFIDelegate
@protocol YKPortScanWIFIDelegate<NSObject>


/// UDP登录回调
/// - Parameters:
///   - ip: ip地址
///   - data: 数据
-(void)ykpswifi_didReceiveUDPMessageWithLogin:(NSString *)ip ykpswifi_data:(NSData *)data;
@end



/// MARK - 端口扫描WIFI
@interface YKPortScanWIFI : NSObject


/// 初始化
/// - Parameters:
///   - port: 端口
///   - delegate: 委托
-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKPortScanWIFIDelegate>)delegate;


/// 在指定端口上启动 UDP 套接字监听器
/// - Parameter error: 指向实际启动错误描述的别名，如果套接字已启动并正在监听，则为 nil
-(BOOL)startWithError:(NSError **)error;


/// 如果套接字正在运行，则停止套接字
-(void)stop;
@end

NS_ASSUME_NONNULL_END

//
//  YKAirPlayServiceRegister.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - AirPlay 服务注册
@interface YKAirPlayServiceRegister : NSObject


/// 初始化AIrPlay镜像注册
/// - Parameter port: 端口
-(instancetype)initWithPort:(int)port;


/// 服务注册
-(BOOL)serviceRegister:(NSString *)airPalyName;


/// 取消注册
-(void)deallocate;
@end

NS_ASSUME_NONNULL_END

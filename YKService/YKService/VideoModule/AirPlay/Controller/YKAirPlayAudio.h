//
//  YKAirPlayAudio.h
//  YKService
//
//  Created by liuxiaobin on 2025/11/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - AirPlay 音频服务
@interface YKAirPlayAudio : NSObject

/// 在指定端口上监听
/// - Parameter error: 错误原因
-(NSDictionary *)startWithError:(NSError **)error;
@end

NS_ASSUME_NONNULL_END

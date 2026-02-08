//
//  YKMjpegService.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - Mjpeg服务类
@interface YKMjpegService : NSObject
@property(nonatomic, assign) UInt16 port;//视频端口
@property(nonatomic, assign) int orientation;//屏幕方向
@end

NS_ASSUME_NONNULL_END

//
//  YKServiceFileLogger.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKSEFileLog [YKServiceFileLogger sharedInstance]

/// MARK - 文件日志
@interface YKServiceFileLogger : NSObject

/// 单例
+(instancetype)sharedInstance;

/// 写入内容
/// - Parameter content: content
-(void)write:(NSString *)content;
@end

NS_ASSUME_NONNULL_END

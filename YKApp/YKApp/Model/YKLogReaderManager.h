//
//  YKLogReaderManager.h
//  Created on 2026/2/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKLogReaderManager                A6f324d8982c2c6f90fdf5b2f63f97f720


/// MARK - 日志读取管理器
@interface YKLogReaderManager : NSObject

/// 单例
+(instancetype)sharedManager;

/**
 开始监听今天的日志
 @param block 每次有新行时的回调
 */
-(void)startReadingTodayLogWithUpdate:(void(^)(NSString *newLog))block;

/** 停止监听 */
-(void)stopMonitoring;
@end

NS_ASSUME_NONNULL_END

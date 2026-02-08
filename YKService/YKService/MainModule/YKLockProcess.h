//
//  YKLockProcess.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/15.
//

#import <Foundation/Foundation.h>


#define YKLockProcess               A81x34456f0065b911796009087b56a7f31
#define lockProcess                 B1e3b41270e019c8f1f7053fbf1ff8a9047

NS_ASSUME_NONNULL_BEGIN

/// MARK - 进程锁
@interface YKLockProcess : NSObject

/// 锁进程
+(void)lockProcess;
@end

NS_ASSUME_NONNULL_END

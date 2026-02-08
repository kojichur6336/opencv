//
//  YKServiceShell.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - Shell
@interface YKServiceShell : NSObject

/// 简单的Shell 命令不带任何返回值
/// - Parameter cmd: 命令
+(void)simple:(NSString *)cmd;


/// 简单的Shell 命令 带有callback返回值
/// - Parameters:
///   - cmd: 命令
///   - completion: 完成
+(void)simple:(NSString *)cmd completion:(nonnull void (^)(BOOL result, NSString * _Nullable msg))completion;


///  执行一个命令并可选捕获其标准输出
/// - Parameters:
///   - args: 命令及其参数，例如 @[ @"/bin/ls", @"-l", @"/" ]
///   - stdOut: 如果不为 NULL，将返回命令的标准输出
///   - flag: 执行标志位（自定义）
+(int)spawnWithArgs:(NSArray<NSString *> *)args
             stdOut:(NSString *_Nonnull*_Nullable)stdOut
               flag:(int)flag;
@end

NS_ASSUME_NONNULL_END

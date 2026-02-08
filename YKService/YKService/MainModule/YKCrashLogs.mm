//
//  YKCrashLogs.m
//  YKService
//
//  Created by liuxiaobin on 2026/1/8.
//

#import <signal.h>
#import <execinfo.h>
#import "YKCrashLogs.h"
#import "YKConstants.h"
#import "YKServiceLogger.h"
#import <Foundation/Foundation.h>



#pragma mark - 内部工具函数

/**
 获取当前堆栈符号数组
 */
static NSArray<NSString *>* YKGetStackSymbols() {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    NSMutableArray<NSString*> *stackSymbols = [NSMutableArray arrayWithCapacity:frames];
    for (int i = 0; i < frames; i++) {
        if (strs[i]) {
            [stackSymbols addObject:[NSString stringWithUTF8String:strs[i]]];
        }
    }
    free(strs);
    return stackSymbols;
}

/**
 核心写入函数：将日志保存为文本
 */
static void YKWriteTextLog(NSString *reason, NSArray *stackSymbols, BOOL isCrash) {
    // 1. 获取基础信息
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentTime = [formatter stringFromDate:[NSDate date]] ?: @"Unknown Time";
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"UnknownBundle";
    NSString *appVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";

    // 2. 拼接文本内容
    NSMutableString *logContent = [NSMutableString string];
    [logContent appendFormat:@"================ Crash Report ================\n"];
    [logContent appendFormat:@"Bundle ID: %@\n", bundleID];
    [logContent appendFormat:@"Version:   %@\n", appVer];
    [logContent appendFormat:@"Time:      %@\n", currentTime];
    [logContent appendFormat:@"Type:      %@\n", isCrash ? @"CRASH_EXCEPTION/SIGNAL" : @"MANUAL_LOG"];
    [logContent appendFormat:@"Reason:    %@\n", reason ?: @"No Reason Provided"];
    
    if (stackSymbols && stackSymbols.count > 0) {
        [logContent appendFormat:@"---------------- Stack Trace ----------------\n"];
        for (NSString *symbol in stackSymbols) {
            [logContent appendFormat:@"%@\n", symbol];
        }
    }
    [logContent appendFormat:@"==============================================\n\n"];
    
    // 3. 路径准备
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *baseDir = kCrashLogs;
    if (![baseDir hasSuffix:@"/"]) {
        baseDir = [baseDir stringByAppendingString:@"/"];
    }

    if (![fm fileExistsAtPath:baseDir]) {
        [fm createDirectoryAtPath:baseDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 文件名格式：Crash_2026-01-08_15-00-00.txt
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *fileDate = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@%@_%@.txt", baseDir, isCrash ? @"YKService_Crash" : @"YKService_Manual", fileDate];
    
    // 4. 同步写入磁盘
    NSError *error = nil;
    BOOL success = [logContent writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!success) {
        LOGI(@"[YKService] 写入日志失败: %@", error.localizedDescription);
    } else {
        LOGI(@"[YKService] %@ 日志已保存到: %@", isCrash ? @"崩溃" : @"手动", fileName);
    }
}

#pragma mark - 异常处理回调

/**
 处理 Objective-C 未捕获的异常 (如 Unrecognized Selector)
 */
void YKUncaughtExceptionHandler(NSException *exception) {
    NSArray *stack = [exception callStackSymbols];
    NSString *reason = [NSString stringWithFormat:@"OC_Exception: %@\nReason: %@", [exception name], [exception reason]];
    
    // 1. 立即写入日志
    YKWriteTextLog(reason, stack, YES);
    
    // 2. 移除所有信号拦截，防止再次进入 YKSignalHandler 造成重复记录
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    // 3. 强行退出进程
    // 注意：如果想保留系统默认的崩溃报告生成，可以用 abort();
    // 但在越狱环境或反调试逻辑中，直接 exit(0) 会更干净。
    exit(0);
}

/**
 处理系统底层的 Unix 信号 (如 SIGSEGV, SIGABRT)
 */
void YKSignalHandler(int signal) {
    NSArray *stack = YKGetStackSymbols();
    NSString *reason = [NSString stringWithFormat:@"Signal %d (%s)", signal, strsignal(signal)];
    
    // 1. 写入文本日志
    YKWriteTextLog(reason, stack, YES);
    
    // 2. 退出
    exit(signal);
}

#pragma mark - 注册信号
void YKCrashLogs::regiSignal() {
    
    // 1. 拦截 Objective-C 异常
    NSSetUncaughtExceptionHandler(&YKUncaughtExceptionHandler);
    
    // 2. 拦截 Unix 信号
    signal(SIGABRT, YKSignalHandler);  // 程序异常终止 (abort)
    signal(SIGILL, YKSignalHandler);   // 非法指令
    signal(SIGSEGV, YKSignalHandler);  // 无效内存访问 (段错误)
    signal(SIGFPE, YKSignalHandler);   // 浮点异常
    signal(SIGBUS, YKSignalHandler);   // 总线错误
    signal(SIGPIPE, YKSignalHandler);  // 管道破裂 (通常发生在 Socket 通信)
}

#pragma mark - 写入崩溃信息
void YKCrashLogs::writeManualLog(NSString *reason) {
    if (!reason) reason = @"Manual Trigger Log";
    
    // 手动日志不需要堆栈，确保写入速度最快
    YKWriteTextLog(reason, nil, NO);
}

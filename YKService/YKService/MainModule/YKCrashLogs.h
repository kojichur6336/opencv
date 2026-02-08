//
//  YKCrashLogs.h
//  YKService
//
//  Created by liuxiaobin on 2026/1/8.
//

#pragma once
#import <Foundation/Foundation.h>

/// MARK - 程序崩溃日志
class YKCrashLogs {
    
public:
    
    // 获取单例实例的静态方法
    static YKCrashLogs& getInstance() {
        static YKCrashLogs instance;
        return instance;
    }
    
    /// 注册信号
    void regiSignal();
    
    
    /// 写入自定义日志
    /// - Parameter reason: 原因
    void writeManualLog(NSString *reason);
};

//
//  YKRecorderRunner.h
//  Created on 2025/10/8
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>
#import "YKClientDeviceProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 录制脚本运行状态
typedef NS_ENUM(NSInteger, YKRecorderRunnerState) {
    /// 初始状态，未加载或未开始
    YKRecorderRunnerStateIdle,
    /// 正在执行脚本
    YKRecorderRunnerStateRunning,
    /// 已暂停执行
    YKRecorderRunnerStatePaused,
    /// 执行完成（正常结束）
    YKRecorderRunnerStateFinished,
    /// 执行过程中出现错误
    YKRecorderRunnerStateError
};


@class YKRecorderRunner;

/// MARK: - 执行回调协议
@protocol YKRecorderRunnerDelegate <NSObject>

@optional

/// 当脚本加载完成时回调
/// - Parameter runner: 当前运行器实例
-(void)recorderRunnerDidLoadScript:(YKRecorderRunner *)runner;

/// 当脚本开始执行时回调
/// - Parameter runner: 当前运行器实例
-(void)recorderRunnerDidStart:(YKRecorderRunner *)runner;

/// 当脚本暂停时回调
/// - Parameter runner: 当前运行器实例
-(void)recorderRunnerDidPause:(YKRecorderRunner *)runner;

/// 当脚本从暂停恢复执行时回调
/// - Parameter runner: 当前运行器实例
-(void)recorderRunnerDidResume:(YKRecorderRunner *)runner;

/// 当脚本执行完成（正常结束）时回调
/// - Parameter runner: 当前运行器实例
-(void)recorderRunnerDidFinish:(YKRecorderRunner *)runner;

/// 当脚本执行出错时回调
/// - Parameters:
///   - runner: 当前运行器实例
///   - error: 错误信息
-(void)recorderRunner:(YKRecorderRunner *)runner didFailWithError:(NSError *)error;


/// 当脚本执行到某一行时的回调
/// - Parameters:
///   - runner: 当前运行器实例
///   - totalLine: 总共多少行
///   - line: 当前行
-(void)recorderRunnerDidRunToLine:(YKRecorderRunner *)runner totalLine:(NSInteger)totalLine currentLine:(NSInteger)line;
@end


/// MARK - 录制脚本执行
@interface YKRecorderRunner : NSObject
@property(nonatomic, weak) id<YKClientDeviceProtocol> receiptObject;//回执Socket
@property (nonatomic, assign, readonly) YKRecorderRunnerState state;//状态
@property (nonatomic, weak, nullable) id<YKRecorderRunnerDelegate> delegate; //用于接收脚本执行状态的回调

/// 加载脚本
/// - Parameter script: 脚本
/// - Parameter repeat: 次数
-(void)loadScript:(NSString *)script repeat:(int)repeat;


/// 开始执行
-(void)start;


/// 暂停执行
-(void)pause;


/// 恢复执行
-(void)resume;


/// 停止执行
-(void)stop;
@end

NS_ASSUME_NONNULL_END

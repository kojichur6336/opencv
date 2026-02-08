//
//  YKClientHeartBeat.m
//  Created on 2025/9/20
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKClientHeartBeat.h"

@interface YKClientHeartBeat()
@property(nonatomic, assign) NSTimeInterval period;//心跳间隔(默认为3秒)
@property(readonly, nonatomic) dispatch_queue_t heartQueue;//心跳队列
@property(readonly, nonatomic) dispatch_source_t heartTimer;//心跳定时
@property(nonatomic, assign) BOOL isHeartTimerSuspended;//是否暂停
@property(nonatomic, weak) id<YKClientHeartBeatDelegate> delegate;
@end

@implementation YKClientHeartBeat

-(instancetype)initWithDelegate:(id<YKClientHeartBeatDelegate>)delegate {
    self = [super init];
    if (self) {
        _period = 300;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - 心跳
-(void)heartBeat {
    
    [self.delegate didReceiveHeartBeat:self];
}


#pragma mark - 设置心跳
-(void)start {
    
    if (_heartTimer) {
        return;
    }
    
    // 获取全局队列
    _heartQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 创建定时器
    _heartTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _heartQueue);
    
    // --- 修改部分开始 ---
    
    // 1. 计算首次触发的延迟时间：从现在起间隔 _period 秒后触发 (解决默认立即执行一次的问题)
    dispatch_time_t startDelay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_period * NSEC_PER_SEC));
    
    // 2. 设置定时器 (删除了原先重复的 dispatch_walltime 调用)
    dispatch_source_set_timer(_heartTimer,
                              startDelay,
                              (uint64_t)(_period * NSEC_PER_SEC),
                              (uint64_t)(1.0 * NSEC_PER_SEC)); // 允许1.0秒误差，降低系统功耗
    
    // 3. 使用弱引用防止循环引用 (解决 self 持有 timer, timer 闭包持有 self 导致无法 dealloc 的问题)
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_heartTimer, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            @autoreleasepool {
                [strongSelf heartBeat];
            }
        }
    });
    
    /// 默认暂停状态需唤醒
    dispatch_resume(_heartTimer);
    _isHeartTimerSuspended = NO;
}

#pragma mark - 停止
-(void)stop
{
    if (_heartTimer) {
        dispatch_source_cancel(_heartTimer);
        _heartTimer = nil;
        _heartQueue = nil;
        _isHeartTimerSuspended = NO;
    }
}

#pragma mark - 释放
-(void)dealloc {
    
    // 取消定时器
    if (_heartTimer) {
        // 如果处于暂停状态，必须先 resume 才能 cancel，否则会崩溃
        if (_isHeartTimerSuspended) {
            dispatch_resume(_heartTimer);
        }
        dispatch_source_cancel(_heartTimer);
        _heartTimer = nil;
    }
}
@end


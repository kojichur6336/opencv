//
//  YKRecorderRunner.m
//  Created on 2025/10/8
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKSimulator.h"
#import "YKServiceLogger.h"
#import "YKRecorderRunner.h"

@interface YKRecorderRunner()
@property(nonatomic, strong) NSThread *thread;//线程
@property(nonatomic, assign) BOOL isPaused;  //是否暂停
@property(nonatomic, strong) dispatch_semaphore_t semaphore; // 信号量
@property(nonatomic, strong) NSArray *scriptData;//脚本内容
@property(nonatomic, assign) BOOL isStopped;    // 是否停止
@property(nonatomic, assign) int64_t repeat;//重复次数
@end

@implementation YKRecorderRunner

#pragma mark - 初始化
-(instancetype)init {
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1); // 创建一个初始为1的信号量
        _isStopped = NO;  // 初始化为未停止
    }
    return self;
}

#pragma mark - 加载脚本
-(void)loadScript:(NSString *)script repeat:(int)repeat
{
    _repeat = repeat;
    if (_repeat == -1) {
        //如果是-1就设置为int64最大值
        _repeat = INT64_MAX;
    }
    
    // 加载脚本并进行必要的解析等操作
    _state = YKRecorderRunnerStateIdle;
    NSArray *lines = [script componentsSeparatedByString:@"\n"];
    self.scriptData = lines;
    [self.delegate recorderRunnerDidLoadScript:self];
}


#pragma mark - 开始执行
-(void)start
{
    if (self.state != YKRecorderRunnerStateIdle)
    {
        return; // 只在空闲状态下开始
    }
    
    _isPaused = NO;
    _isStopped = NO;
    _state = YKRecorderRunnerStateRunning;
    [self.delegate recorderRunnerDidStart:self];
    [self.thread start];
}

#pragma mark - 暂停执行
-(void)pause {
    
    if (self.state != YKRecorderRunnerStateRunning)
    {
        return; // 只有在运行状态才能暂停
    }
    
    _isPaused = YES;
    _state = YKRecorderRunnerStatePaused;
    
    // 信号量减1，模拟暂停时的阻塞
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [self.delegate recorderRunnerDidPause:self];
}

#pragma mark - 恢复执行
-(void)resume {
    
    if (self.state != YKRecorderRunnerStatePaused)
    {
        return; // 只有在暂停状态才能恢复
    }
    
    _isPaused = NO;
    _state = YKRecorderRunnerStateRunning;
    
    // 每次恢复时，信号量需要被释放，确保线程继续执行
    dispatch_semaphore_signal(_semaphore);
    
    [self.delegate recorderRunnerDidResume:self];
}


#pragma mark - 停止执行
-(void)stop
{
    if (self.state == YKRecorderRunnerStateIdle || self.state == YKRecorderRunnerStateFinished || self.state == YKRecorderRunnerStateError) {
        LOGI(@"不在运行或暂停状态时无法停止");
        return;
    }
    
    _isStopped = YES; // 标记停止状态
    _state = YKRecorderRunnerStateFinished; // 直接标记为完成状态
    [self.thread cancel];
    self.thread = nil;
    [YKSimulator clear];
    
    [self.delegate recorderRunnerDidFinish:self];
}

#pragma mark - 运行脚本
-(void)runScript {
    
    // 当前行号
    NSInteger currentLine = 0;
    NSInteger remainingRepeats = _repeat;
    NSInteger totalLine = self.scriptData.count;
    
    while (remainingRepeats > 0) {
        currentLine = 0;
        for (NSString *line in self.scriptData) {
            if (_isPaused) {
                // 在暂停状态下，等待信号量
                dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER); // 等待信号量
            }
            
            // 如果脚本已停止，立即退出
            if (_isStopped) {
                LOGI(@"脚本执行被停止");
                return; // 如果脚本已停止，则退出执行
            }
            
            currentLine++;  // 增加当前行号
            [self.delegate recorderRunnerDidRunToLine:self totalLine:totalLine currentLine:currentLine];
            
            NSArray *components = [line componentsSeparatedByString:@" "];
            if ([components.firstObject hasPrefix:@"YKTouchDownEvent"]) {
                NSArray *pointComponents = [components[1] componentsSeparatedByString:@","];
                CGPoint point = CGPointMake([pointComponents[2] intValue], [pointComponents[3] intValue]);
                int duration = [pointComponents[0] intValue];
                int fingerId = [pointComponents[1] intValue];
                [self sleep:duration];
                [YKSimulator touchDown:point fingerId:fingerId];
            } else if ([components.firstObject hasPrefix:@"YKTouchMoveEvent"]) {
                NSArray *pointComponents = [components[1] componentsSeparatedByString:@","];
                CGPoint point = CGPointMake([pointComponents[2] intValue], [pointComponents[3] intValue]);
                int duration = [pointComponents[0] intValue];
                int fingerId = [pointComponents[1] intValue];
                [YKSimulator touchMove:point fingerId:fingerId duration:duration];
            } else if ([components.firstObject hasPrefix:@"YKTouchUpEvent"]) {
                NSArray *pointComponents = [components[1] componentsSeparatedByString:@","];
                CGPoint point = CGPointMake([pointComponents[2] intValue], [pointComponents[3] intValue]);
                int duration = [pointComponents[0] intValue];
                int fingerId = [pointComponents[1] intValue];
                [YKSimulator touchUp:point fingerId:fingerId];
                [self sleep:duration];
            }
        }
        
        remainingRepeats -= 1;
    }
    
    // 执行完成后，更新状态
    _state = YKRecorderRunnerStateFinished; // 直接标记为完成状态
    [self.thread cancel];
    self.thread = nil;
    [self.delegate recorderRunnerDidFinish:self];
}



#pragma mark - 睡眠
-(void)sleep:(unsigned int)duration {
    
    if (duration == 0) {
        return;
    }
    
    // 计算秒数和毫秒数
    int iSecond = duration / 1000, iMilliSecond = (duration % 1000);
    
    // 先 delay 秒数
    while (iSecond > 0) {
        // 检查是否已停止，如果已停止，则立即返回
        if (_isStopped) {
            return;
        }
        
        struct timeval delay_second = { 0 };
        delay_second.tv_sec = 1;
        select(0, NULL, NULL, NULL, &delay_second); //阻塞毫秒数
        iSecond--;
        
        // 每秒钟 delay 后，要判断脚本是否已经停止
        if (_isStopped) {
            return;
        }
        
        // 如果在暂停状态下，等待信号量恢复
        if (_isPaused) {
            dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    // 再 delay 毫秒数
    struct timeval delay_usec = { 0 };
    delay_usec.tv_usec = iMilliSecond * 1000;
    select(0, NULL, NULL, NULL, &delay_usec); // 阻塞毫秒数
    // 毫秒 delay 后也需要判断是否停止
    if (_isStopped) {
        return;
    }
    
    // 如果在暂停状态下，等待信号量恢复
    if (_isPaused) {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    }
}


#pragma mark - lazy
-(NSThread *)thread {
    if (!_thread) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(runScript) object:nil];
    }
    return _thread;
}
@end

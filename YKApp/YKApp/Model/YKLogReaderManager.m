//
//  YKLogReaderManager.m
//  Created on 2026/2/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <fcntl.h>
#import <unistd.h>
#import "YKAppLogger.h"
#import "YKLogReaderManager.h"

@interface YKLogReaderManager ()
@property(nonatomic, strong) dispatch_source_t source;
@property(nonatomic, assign) int fileDescriptor;
@property(nonatomic, assign) unsigned long long lastOffset;
@property(nonatomic, strong) dispatch_queue_t readQueue;
@property(nonatomic, strong) NSTimer *dateCheckTimer;
@property(nonatomic, copy) NSString *currentLogPath;
@property(nonatomic, copy) void(^updateBlock)(NSString *);
@end


@implementation YKLogReaderManager

+ (instancetype)sharedManager {
    static YKLogReaderManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[YKLogReaderManager alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _readQueue = dispatch_queue_create("com.yk.log.reader", DISPATCH_QUEUE_SERIAL);
        _fileDescriptor = -1;
    }
    return self;
}

#pragma mark - 获取当天的日志文件名路径
-(NSString *)getTodayLogPath {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    // 这里的路径根据你的描述修改
    NSString *dir = @"/var/mobile/Library/YKApp/Logs/";
    
    // 越狱环境下确保文件夹存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        // App端通常只有读权限，这里假设后台进程已经创建了目录
        LOGI(@"进入没有权限流程");
        return nil;
    }
    
    return [dir stringByAppendingFormat:@"YKService%@.txt", dateStr];
}

- (void)startReadingTodayLogWithUpdate:(void(^)(NSString *))block {
    self.updateBlock = block;
    [self setupMonitoring];
    
    // 开启一个定时器，每天凌晨检查一下是否需要切换新文件
    if (!_dateCheckTimer) {
        _dateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkDateChange) userInfo:nil repeats:YES];
    }
}

- (void)setupMonitoring {
    [self stopMonitoring];
    
    NSString *path = [self getTodayLogPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), self.readQueue, ^{
            [self setupMonitoring];
        });
        return;
    }
    
    self.currentLogPath = path;
    self.fileDescriptor = open([path UTF8String], O_RDONLY | O_NONBLOCK);
    if (self.fileDescriptor == -1) return;

    // --- 修改点：从 0 开始读取，即加载文件所有内容 ---
    self.lastOffset = 0;

    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, self.fileDescriptor, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME, self.readQueue);

    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.source, ^{
        unsigned long data = dispatch_source_get_data(weakSelf.source);
        if (data & DISPATCH_VNODE_WRITE) {
            [weakSelf readNewData];
        }
        if (data & (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf setupMonitoring];
            });
        }
    });

    dispatch_source_set_cancel_handler(self.source, ^{
        if (weakSelf && weakSelf.fileDescriptor != -1) {
            close(weakSelf.fileDescriptor);
            weakSelf.fileDescriptor = -1;
        }
    });

    dispatch_resume(self.source);
    
    // --- 修改点：启动监听后，立即手动调用一次读取，把已有的历史数据发给界面 ---
    dispatch_async(self.readQueue, ^{
        [self readNewData];
    });
}

#pragma mark - 读取新的行号数据
-(void)readNewData {
    // 越狱进程读取，建议直接用系统级 read 或 NSFileHandle
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.currentLogPath];
    if (!handle) return;
    
    [handle seekToFileOffset:_lastOffset];
    NSData *data = [handle readDataToEndOfFile];
    _lastOffset = [handle offsetInFile];
    [handle closeFile];
    
    if (data.length > 0) {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (str && self.updateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.updateBlock(str);
            });
        }
    }
}

#pragma mark - 检查日期是否变更（比如过了午夜）
-(void)checkDateChange {
    NSString *todayPath = [self getTodayLogPath];
    if (![todayPath isEqualToString:self.currentLogPath]) {
        LOGI(@"日期翻篇，切换日志文件");
        [self setupMonitoring];
    }
}

#pragma mark - 停止监听
-(void)stopMonitoring {
    
    if (_source) {
        dispatch_source_cancel(_source);
        _source = nil;
    }
    if (_fileDescriptor != -1) {
        close(_fileDescriptor);
        _fileDescriptor = -1;
    }
}
@end

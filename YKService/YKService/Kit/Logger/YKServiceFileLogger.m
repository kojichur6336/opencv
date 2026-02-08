//
//  YKServiceFileLogger.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKServiceFileLogger.h"

#define kYSJSBDirectory @"/var/mobile/Library/YKApp/Logs"

@implementation YKServiceFileLogger

+(instancetype)sharedInstance {
    
    static YKServiceFileLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


#pragma mark - 写入文件
-(void)write:(NSString *)content {
    
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self privateWrite:content];
        });
        
    } else {
        [self privateWrite:content];
    }
}

#pragma mark - 私有方法
-(void)privateWrite:(NSString *)content {
    
    // 获取当前日期格式化的文件名
    NSString *fileName = [self currentDateLogFileName];
    NSString *filePath = [kYSJSBDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查文件是否存在
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    
    NSFileHandle *fileHandle = nil;
    if (fileExists) {
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    } else {
        // 创建新文件
        if (![fileManager createFileAtPath:filePath contents:nil attributes:nil]) {
            return;
        }
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    
    if (!fileHandle) {
        return;
    }
    
    @try {
        
        // 准备日志内容
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setDateFormat:@"HH:mm:ss:SSS"];
        NSString *currentTime = [timeFormatter stringFromDate:[NSDate date]];
        
        NSString *logEntry = [NSString stringWithFormat:@"%@ %@\n", currentTime, content];
        
        // 写入文件
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
    } @finally {
        [fileHandle closeFile];
    }
}

#pragma mark - 获取当前日期的日志文件名
-(NSString *)currentDateLogFileName {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"YKService%@.txt", dateString];
}
@end

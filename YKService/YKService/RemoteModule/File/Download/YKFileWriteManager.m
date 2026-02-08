//
//  YKFileWriteManager.m
//  Created on 2025/9/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKServiceLogger.h"
#import "YKFileWriteManager.h"

@interface YKFileWriteManager()
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation YKFileWriteManager

#pragma mark - 初始化
-(instancetype)initWithFilePath:(NSString *)filePath error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    self = [super init];
    if (self) {
        
        _path = filePath;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:nil];//先删除上一个路径
        if (![fileManager fileExistsAtPath:filePath])
        {
            BOOL result = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            if (!result) {
                *error = [NSError errorWithDomain:@"com.sky.yk.createFile"
                                                            code:1001
                                                        userInfo:@{NSLocalizedDescriptionKey : @"权限不足"}];
                return nil;
            }
        }
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [_fileHandle seekToEndOfFile]; // 将文件偏移量设置到文件末尾
    }
    return self;
}


#pragma mark - 写入
-(void)writeData:(NSData *)data {
    // 将数据写入文件
    [_fileHandle writeData:data];
}

#pragma mark - 关闭
-(void)close {
    
    if (self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
    }
}

#pragma mark - 写入失败，删除文件
-(void)fail
{
    [self close];
    // 删除文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:&error];
    }
}

#pragma mark - 释放
-(void)dealloc {
    [_fileHandle closeFile];
}
@end

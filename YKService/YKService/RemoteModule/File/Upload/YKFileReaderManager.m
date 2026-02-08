//
//  YKFileReaderManager.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKServiceLogger.h"
#import "YKFileReaderManager.h"

@interface YKFileReaderManager()
@property(nonatomic, assign) long long int chunkSize;//默认读取大小
@property(nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation YKFileReaderManager

#pragma mark - 初始化
-(instancetype)initWithFilePath:(NSString *)filePath chunkSize:(long long)chunkSize error:(NSError *__autoreleasing  _Nullable *)error {
    self = [super init];
    if (self) {
        
        _filePath = [filePath copy];
        _chunkSize = chunkSize;
        
        // 文件路径检查
        NSError *checkError = [self checkFileExistenceAtPath:filePath];
        if (checkError) {
            *error = checkError;
            return nil;
        }
        
        
        // 获取文件大小
        NSError *sizeError = nil;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&sizeError];
        unsigned long long fileSize = [attrs fileSize];
        if (sizeError || !attrs) {
            *error = [self createErrorWithDescription:@"读取文件大小失败"];
            return nil;
        }
        
        _totalSize = fileSize;
        
        
        // 打开文件
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        if (!_fileHandle) {
            *error = [self createErrorWithDescription:@"无法打开文件"];
            return nil;
        }
        _offset = 0;
        
    }
    return self;
}

#pragma mark - 检查文件的存在性、类型和可读性
- (NSError *)checkFileExistenceAtPath:(NSString *)filePath {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    
    if (!exists) {
        return [self createErrorWithDescription:@"文件不存在，无法上传"];
    }
    
    if (isDir) {
        return [self createErrorWithDescription:@"不能直接上传文件夹，请先压缩后再上传"];
    }
    
    if (![[NSFileManager defaultManager] isReadableFileAtPath:filePath]) {
        return [self createErrorWithDescription:@"没有权限读取该文件，无法上传"];
    }
    
    return nil; // 没有错误
}

#pragma mark - 创建统一的错误
-(NSError *)createErrorWithDescription:(NSString *)description {
    return [NSError errorWithDomain:@"com.sky.yk.file"
                               code:2
                           userInfo:@{NSLocalizedDescriptionKey : description}];
}


#pragma mark - 读取下一块
-(NSData *)readNextChunk
{
    if (![self hasMoreData])
    {
        return nil;
    }
    
    @try {
        
        unsigned long long remaining = _totalSize - _offset;
        NSUInteger length = (NSUInteger)MIN(self.chunkSize, remaining);
        
        [_fileHandle seekToFileOffset:_offset];
        NSData *data = [_fileHandle readDataOfLength:length];
        _offset += data.length;
        return data;
    } @catch (NSException *exception) {
        LOGI(@"文件读取异常: %@", exception.reason);
        return nil;
    }
}

#pragma mark - 是否还有数据
-(BOOL)hasMoreData {
    return _offset < _totalSize;
}

#pragma mark - 重置到开头
-(void)reset
{
    _offset = 0;
    [_fileHandle seekToFileOffset:0];
}

#pragma mark - 关闭文件句柄
-(void)close
{
    if (_fileHandle) {
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
}

#pragma mark - 释放
-(void)dealloc {
    [self close];
}
@end

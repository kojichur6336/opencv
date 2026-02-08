//
//  YKFileReaderManager.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件读取管理
@interface YKFileReaderManager : NSObject
@property (nonatomic, strong, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) unsigned long long totalSize;
@property (nonatomic, assign, readonly) unsigned long long offset;


/// 初始化
/// - Parameter filePath: 文件路径
/// - Parameter chunkSize:
/// - Parameter error: 错误原因
-(instancetype)initWithFilePath:(NSString *)filePath chunkSize:(long long int)chunkSize error:(NSError **)error;


/// 读取下一块
-(NSData *)readNextChunk;

/// 是否还有数据
-(BOOL)hasMoreData;


/// 重置到开头
-(void)reset;


/// 关闭文件句柄
-(void)close;
@end

NS_ASSUME_NONNULL_END

//
//  YKFileWriteManager.h
//  Created on 2025/9/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件写入管理类
@interface YKFileWriteManager : NSObject

/// 初始化写入路径
/// - Parameter filePath: 路径
-(instancetype)initWithFilePath:(NSString *)filePath error:(NSError **)error;

/// 写入数据
/// - Parameter data: data
-(void)writeData:(NSData *)data;


/// 关闭写入
-(void)close;


/// 写入失败
-(void)fail;
@end

NS_ASSUME_NONNULL_END

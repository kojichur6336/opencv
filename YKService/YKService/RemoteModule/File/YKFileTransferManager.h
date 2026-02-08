//
//  YKFileTransferManager.h
//  Created on 2025/9/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKFileUploadModel.h"
#import "YKFileDownloadModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 文件传输管理类
@interface YKFileTransferManager : NSObject

/// 添加文件下载
/// - Parameter model: 文件下载对象
-(void)addFileDownloadModel:(YKFileDownloadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(void (^)(BOOL success, NSString *msg))completion;



/// 添加文件上传
/// - Parameter model: 文件上传对象
-(void)addFileUploadModel:(YKFileUploadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(nonnull void (^)(BOOL success, NSString * msg))completion;
@end

NS_ASSUME_NONNULL_END

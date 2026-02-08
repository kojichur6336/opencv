//
//  YKFileUploadModel.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKClientDeviceProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件上传实体
@interface YKFileUploadModel : NSObject
@property(nonatomic, copy) NSString *identity;// 唯一标识
@property(nonatomic, copy) NSString *ip;//地址(如果为空代表USB本地127.0.0.1)
@property(nonatomic, assign) int port;//端口
@property(nonatomic, copy) NSString *path;//本地路径
@property(nonatomic, assign) long long int totalBytesSent;//已发送大小
@property(nonatomic, assign) long long int totalFileSize;//文件总大小
@end

NS_ASSUME_NONNULL_END

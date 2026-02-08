//
//  YKFileDownloadModel.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKClientDeviceProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件下载实体
@interface YKFileDownloadModel : NSObject
@property(nonatomic, copy) NSString *identity;// 唯一标识
@property(nonatomic, copy) NSString *ip;//ip(如果IP地址为空就代表是USB下载)
@property(nonatomic, assign) int port;//端口
@property(nonatomic, copy) NSString *path;//地址
@property(nonatomic, assign) long long int totalFileSize;//文件大小
@property(nonatomic, assign) long long int totalBytesReceived;//已接收大小
@end

NS_ASSUME_NONNULL_END

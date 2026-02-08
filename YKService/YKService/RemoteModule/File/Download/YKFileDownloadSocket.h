//
//  YKFileDownloadSocket.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKFileDownloadModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件下载Socket类
@interface YKFileDownloadSocket : NSObject
@property(nonatomic, weak) YKFileDownloadModel *model;//下载实体

/// 初始化文件实体
/// - Parameters:
///   - model: 模型
///   - portCallback: 端口回调(USB通用)
///   - completion: 完成
-(instancetype)initWithModel:(YKFileDownloadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(void (^)(BOOL success, NSString *msg))completion;


/// 开始
-(void)start;


/// 停止
-(void)stop;

@end

NS_ASSUME_NONNULL_END

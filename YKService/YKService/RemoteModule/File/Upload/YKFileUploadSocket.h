//
//  YKFileUploadSocket.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKFileUploadModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件上传Socket
@interface YKFileUploadSocket : NSObject
@property(nonatomic, weak) YKFileUploadModel *model;//上传实体

/// 初始化
/// - Parameters:
///   - model: 上传实体
///   - portCallback: 端口回调
///   - completion: 完成回调
-(instancetype)initWithModel:(YKFileUploadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(void (^)(BOOL success, NSString *msg))completion;


/// 开始
-(void)start;


/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

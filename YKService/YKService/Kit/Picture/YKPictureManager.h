//
//  YKPictureManager.h
//  YKService
//
//  Created by liuxiaobin on 2025/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 相册管理类
@interface YKPictureManager : NSObject

/// 解压图片处理
/// - Parameters:
///   - dataPath: 数据路径
///   - completion: 回调
+(void)decompressionProcess:(NSString *)fullPath completion:(void (^)(BOOL success, NSString *message))completion;


/// 删除相册所有数据
/// - Parameter completionHandler: 完成
+(void)deleteAllPhotos:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END

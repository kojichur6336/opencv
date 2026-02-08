//
//  YKArchive.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 解压压缩类
@interface YKArchive : NSObject

/// 单例
+(instancetype)sharedInstance;

/// 解压
/// - Parameters:
///   - filePath: 目标路径
///   - completion: 完成回调
-(void)extractArchiveAtPath:(NSString *)filePath
                 completion:(void (^)(BOOL success, NSString *msg, NSString *filePath))completion;



/// 压缩文件或文件夹
/// - Parameters:
///   - archivePath: 目标文件
///   - completion: 完成回调
-(void)compressArchiveAtPath:(NSString *)archivePath completion:(void (^)(BOOL success, NSString *msg, NSString *zipPath))completion;
@end

NS_ASSUME_NONNULL_END

//
//  YKServiceFileManager.h
//  YKService
//
//  Created by liuxiaobin on 2025/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 文件管理类
@interface YKServiceFileManager : NSObject

/// 获取单个文件信息
/// - Parameter path: 路径
+(NSDictionary *)getFileInfo:(NSString *)path;


/// 获取文件列表信息
/// - Parameter path: 路径
+(NSArray<NSDictionary *> *)findFileListInfo:(NSString *)path;


/// 新建文件夹
/// - Parameters:
///   - folderPath: 文件夹
///   - completion: 完成回调 (success, error)
+(void)createDirectoryAtPath:(NSString *)folderPath
                  completion:(void (^)(BOOL success, NSString * error))completion;


/// 重命名文件/文件夹
/// - Parameters:
///   - oldPath: 原路径
///   - newName: 新名字（不包含路径，只是最后的文件/目录名）
///   - completion: 完成回调 (success, error)
+(void)renameItemAtPath:(NSString *)oldPath
                  toName:(NSString *)newName
              completion:(void (^)(BOOL success, NSString * error))completion;



/// 删除文件/文件夹
/// - Parameters:
///   - itemPath: 文件或文件夹完整路径
///   - completion: 完成回调 (success, error)
+(void)deleteItemAtPath:(NSString *)itemPath
              completion:(void (^)(BOOL success,  NSString  * error))completion;
@end

NS_ASSUME_NONNULL_END

//
//  YKApplicationManager.h
//  Created on 2025/10/15
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^InstallCompletionBlock)(BOOL result, NSString * msg);
typedef void (^AppsListCompletionBlock)(NSMutableArray<NSDictionary *> *result);

/// MARK - 应用管理
@interface YKApplicationManager : NSObject


/// 安装App
/// - Parameters:
///   - path: 路径
///   - completion: 完成
+(void)installApp:(NSString *)path completion:(InstallCompletionBlock)completion;


/// 获取用户App列表
/// - Parameter completion: 回调
+(void)getAppsList:(AppsListCompletionBlock)completion;


/// 卸载App
/// - Parameter bundleId: 包名
+(BOOL)uninstallApp:(NSString *)bundleId;


/// 是否Deb
/// - Parameter debName: 包名
+(BOOL)isDebPackage:(NSString *)bundleId;


/// 清除缓存数据
/// - Parameter identifier: 包名
+(void)clearCache:(NSString *)identifier;


/// 清除钥匙串
/// - Parameter identifier: 包名
+(void)clearKeyChain:(NSString *)identifier;


/// 启动App
/// - Parameter bundleId: 包名
+(BOOL)launch:(NSString *)bundleId;


/// 获取指定包名的版本号
/// - Parameter bundleID: 包名
+(NSString *)getVersionForBundleIdentifier:(NSString *)bundleID;
@end

NS_ASSUME_NONNULL_END

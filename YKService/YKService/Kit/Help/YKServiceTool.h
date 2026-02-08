//
//  YKServiceTool.h
//  Created on 2025/9/20
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 工具类
@interface YKServiceTool : NSObject

/// 越狱类型
+(int)jbType;


/// 转换路径
/// - Parameter path: 路径
+(NSString *)conversionJBRoot:(NSString *)path;


/// 获取可用内存
+(unsigned long long)freeDiskSpace;


/// 获取本地IP地址
+(NSString *)getIpAddresses;


/// 获取设备型号
+(NSString *)platform;


/// 系统版本
+(NSInteger)numbericOSVersion;


/// 比较当前系统版本与目标版本之间的大小关系
/// - Parameters: 返回 NSComparisonResult 枚举类型：
///   - currentVersion: 当前版本低于目标版本
///   - targetVersion: 当前版本与目标版本相同
+ (NSComparisonResult)compareSystemVersion:(nonnull NSString *)currentVersion toVersion:(nonnull NSString *)targetVersion;


/// 判断当前系统是否至少为指定版本
/// - Parameter targetVersion: 如果当前系统版本大于或等于目标版本，返回 YES；否则返回 NO
+ (BOOL)isCurrentSystemAtLeastVersion:(nonnull NSString *)targetVersion;


/// 判断当前系统是否低于指定版本
/// - Parameter targetVersion: 如果当前系统版本小于目标版本，返回 YES；否则返回 NO
+ (BOOL)isCurrentSystemLowerThanVersion:(nonnull NSString *)targetVersion;


/// md5编码
/// - Parameter data: data
+(NSString *)md5ForData:(NSData *)data;


/// 计算MD5来自文件
/// - Parameter filePath: 文件路径
/// - Parameter totalLength: 总长度
+(NSString *)calculateMD5ForFile:(NSString *)filePath totalLength:(NSUInteger)totalLength;


/// JSON解析
+(NSDictionary *)jsonData:(NSData *)data;


/// 字典转Data JSON
+(NSData *)dataFromDictionary:(NSDictionary *)dic;


/// 字典转 Plist 数据
/// - Parameter dic: 需要转换的字典
/// - Returns: 对应的 Plist 格式的 NSData 数据
+(NSData *)plistDataFromDictionary:(NSDictionary *)dic;


/// 获取应用icon 图标
/// - Parameter identifier: 包名
+(UIImage *)getAppIconForIdentifier:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END

//
//  YKServiceTool.m
//  Created on 2025/9/20
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//


#import <fts.h>
#import <dlfcn.h>
#import <dirent.h>
#import <stdlib.h>
#import <ifaddrs.h>
#import <sys/stat.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Photos/Photos.h>
#import "YKServiceTool.h"
#import "YKServiceLogger.h"
#import <ImageIO/ImageIO.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CommonCrypto/CommonDigest.h>

#if defined(ROOTHIDE)
#import "roothide.h"
#endif


#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"

@implementation YKServiceTool

#pragma mark - 越狱类型
+(int)jbType {
#if defined(ROOTLESS)
    return 2;
#elif defined(ROOTHIDE)
    return 3;
#else
    return 1;
#endif
}


#pragma mark - 转换路径
+(NSString *)conversionJBRoot:(NSString *)path {
    
#if ROOTLESS
    return [NSString stringWithFormat:@"/var/jb%@",path];
#elif ROOTHIDE
    return  @(jbroot(path.UTF8String));
#else
    return path;
#endif
}

#pragma mark - 获取可用内存
+(unsigned long long)freeDiskSpace {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [attrs[NSFileSystemFreeSize] unsignedLongLongValue];
}

#pragma mark - 获取IP地址
+(NSString *)getIpAddresses {
    
    NSString *address = @"error";
    NSMutableArray *addresses = [NSMutableArray array];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                NSString *ifaName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *ipAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                if ([ifaName hasPrefix:@"en"]) {
                    if (![ipAddress hasPrefix:@"169.254"]) {
                        [addresses insertObject:ipAddress atIndex:0];
                    }
                } else if ([ifaName isEqualToString:IOS_WIFI] || [ifaName isEqualToString:IOS_CELLULAR]) {
                    [addresses addObject:ipAddress];
                } else if ([ifaName isEqualToString:IOS_VPN]) {
                    [addresses addObject:ipAddress];
                }
                
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    if (addresses.count > 0) {
        address = [addresses componentsJoinedByString:@";"];
    }
    return address;
}

#pragma mark - 编码
+(NSString *)md5ForData:(NSData *)data {
    
    // 创建一个字符数组来存放哈希值
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // 使用 CC_MD5 函数计算 MD5 哈希值
    CC_MD5(data.bytes, (CC_LONG)data.length, md5Buffer);
    
    // 将哈希值转换为字符串
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", md5Buffer[i]];
    }
    return [md5String copy];
}

#pragma mark - 计算文件大小
+(NSString *)calculateMD5ForFile:(NSString *)filePath totalLength:(NSUInteger)totalLength {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!fileHandle) {
        LOGI(@"打开文件路径错误: %@", filePath);
        return nil;
    }
    
    CC_MD5_CTX md5Context;
    CC_MD5_Init(&md5Context);
    
    NSUInteger readLength = 0;
    NSData *fileData;
    while (readLength < totalLength && (fileData = [fileHandle readDataOfLength:MIN(1024 * 1024, totalLength - readLength)])) {
        CC_MD5_Update(&md5Context, [fileData bytes], (CC_LONG)[fileData length]);
        readLength += [fileData length];
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5Context);
    
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", digest[i]];
    }
    
    [fileHandle closeFile]; // 关闭文件
    return [md5String copy];
}

#pragma mark - 设备型号
+(NSString *)platform {
    
    //https://github.com/Tencent/QMUI_iOS
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // iPhone
    if ([deviceString isEqualToString:@"iPhone3,1"] || [deviceString isEqualToString:@"iPhone3,2"] || [deviceString isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"] || [deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"] || [deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone6,1"] || [deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6S";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6S Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([deviceString isEqualToString:@"iPhone9,1"] || [deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,2"] || [deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    if ([deviceString isEqualToString:@"iPhone10,1"] || [deviceString isEqualToString:@"iPhone10,4"])  return @"iPhone 8";
    if ([deviceString isEqualToString:@"iPhone10,2"] || [deviceString isEqualToString:@"iPhone10,5"])  return @"iPhone 8 Plus";
    if ([deviceString isEqualToString:@"iPhone10,3"] || [deviceString isEqualToString:@"iPhone10,6"])  return @"iPhone X";
    if ([deviceString isEqualToString:@"iPhone11,2"])    return @"iPhone XS";
    if ([deviceString isEqualToString:@"iPhone11,4"] || [deviceString isEqualToString:@"iPhone11,6"])  return @"iPhone XS Max";
    if ([deviceString isEqualToString:@"iPhone11,8"])    return @"iPhone XR";
    if ([deviceString isEqualToString:@"iPhone12,1"])    return @"iPhone 11";
    if ([deviceString isEqualToString:@"iPhone12,3"])    return @"iPhone 11 Pro";
    if ([deviceString isEqualToString:@"iPhone12,5"])    return @"iPhone 11 Pro Max";
    if ([deviceString isEqualToString:@"iPhone12,8"])    return @"iPhone SE (2nd generation)";
    if ([deviceString isEqualToString:@"iPhone13,1"])    return @"iPhone 12 Mini";
    if ([deviceString isEqualToString:@"iPhone13,2"])    return @"iPhone 12";
    if ([deviceString isEqualToString:@"iPhone13,3"])    return @"iPhone 12 Pro";
    if ([deviceString isEqualToString:@"iPhone13,4"])    return @"iPhone 12 Pro Max";
    if ([deviceString isEqualToString:@"iPhone14,4"])    return @"iPhone 13 Mini";
    if ([deviceString isEqualToString:@"iPhone14,5"])    return @"iPhone 13";
    if ([deviceString isEqualToString:@"iPhone14,2"])    return @"iPhone 13 Pro";
    if ([deviceString isEqualToString:@"iPhone14,3"])    return @"iPhone 13 Pro Max";
    if ([deviceString isEqualToString:@"iPhone14,6"])    return @"iPhone SE (3rd generation)";
    if ([deviceString isEqualToString:@"iPhone14,7"])    return @"iPhone 14";
    if ([deviceString isEqualToString:@"iPhone14,8"])    return @"iPhone 14 Plus";
    if ([deviceString isEqualToString:@"iPhone15,2"])    return @"iPhone 14 Pro";
    if ([deviceString isEqualToString:@"iPhone15,3"])    return @"iPhone 14 Pro Max";
    if ([deviceString isEqualToString:@"iPhone15,4"])    return @"iPhone 15";
    if ([deviceString isEqualToString:@"iPhone15,5"])    return @"iPhone 15 Plus";
    if ([deviceString isEqualToString:@"iPhone16,1"])    return @"iPhone 15 Pro";
    if ([deviceString isEqualToString:@"iPhone16,2"])    return @"iPhone 15 Pro Max";
    if ([deviceString isEqualToString:@"iPhone17,1"])    return @"iPhone 16 Pro";
    if ([deviceString isEqualToString:@"iPhone17,2"])    return @"iPhone 16 Pro Max";
    if ([deviceString isEqualToString:@"iPhone17,3"])    return @"iPhone 16";
    if ([deviceString isEqualToString:@"iPhone17,4"])    return @"iPhone 16 Plus";
    if ([deviceString isEqualToString:@"iPhone17,5"])    return @"iPhone 16e";
    if ([deviceString isEqualToString:@"iPhone18,1"])    return @"iPhone 17 Pro";
    if ([deviceString isEqualToString:@"iPhone18,2"])    return @"iPhone 17 Pro Max";
    if ([deviceString isEqualToString:@"iPhone18,3"])    return @"iPhone 17";
    if ([deviceString isEqualToString:@"iPhone18,4"])    return @"iPhone Air";
    
    
    // iPod
    if ([deviceString isEqualToString:@"iPod1,1"]) return @"iPod Touch 1";
    if ([deviceString isEqualToString:@"iPod2,1"]) return @"iPod Touch 2";
    if ([deviceString isEqualToString:@"iPod3,1"]) return @"iPod Touch 3";
    if ([deviceString isEqualToString:@"iPod4,1"]) return @"iPod Touch 4";
    if ([deviceString isEqualToString:@"iPod5,1"]) return @"iPod Touch 5";
    if ([deviceString isEqualToString:@"iPod7,1"]) return @"iPod Touch 6";
    if ([deviceString isEqualToString:@"iPod9,1"]) return @"iPod Touch 7";
    
    // iPad
    if ([deviceString isEqualToString:@"iPad1,1"]) return @"iPad 1";
    if ([deviceString isEqualToString:@"iPad2,1"] || [deviceString isEqualToString:@"iPad2,2"] || [deviceString isEqualToString:@"iPad2,3"] || [deviceString isEqualToString:@"iPad2,4"]) return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad3,1"] || [deviceString isEqualToString:@"iPad3,2"] || [deviceString isEqualToString:@"iPad3,3"]) return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,4"] || [deviceString isEqualToString:@"iPad3,5"] || [deviceString isEqualToString:@"iPad3,6"]) return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad6,11"] || [deviceString isEqualToString:@"iPad6,12"]) return @"iPad 5";
    if ([deviceString isEqualToString:@"iPad7,5"] || [deviceString isEqualToString:@"iPad7,6"]) return @"iPad 6";
    if ([deviceString isEqualToString:@"iPad7,11"] || [deviceString isEqualToString:@"iPad7,12"]) return @"iPad 7";
    if ([deviceString isEqualToString:@"iPad11,6"] || [deviceString isEqualToString:@"iPad11,7"]) return @"iPad 8";
    if ([deviceString isEqualToString:@"iPad12,1"] || [deviceString isEqualToString:@"iPad12,2"]) return @"iPad 9";
    if ([deviceString isEqualToString:@"iPad13,18"] || [deviceString isEqualToString:@"iPad13,19"]) return @"iPad 10";
    
    if ([deviceString isEqualToString:@"iPad4,1"] || [deviceString isEqualToString:@"iPad4,2"] || [deviceString isEqualToString:@"iPad4,3"]) return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"] || [deviceString isEqualToString:@"iPad5,4"]) return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad11,3"] || [deviceString isEqualToString:@"iPad11,4"]) return @"iPad Air 3";
    if ([deviceString isEqualToString:@"iPad13,1"] || [deviceString isEqualToString:@"iPad13,2"]) return @"iPad Air 4";
    if ([deviceString isEqualToString:@"iPad13,16"] || [deviceString isEqualToString:@"iPad13,17"]) return @"iPad Air 5";
    if ([deviceString isEqualToString:@"iPad14,8"] || [deviceString isEqualToString:@"iPad14,9"]) return @"iPad Air 11-inch (M2)";
    if ([deviceString isEqualToString:@"iPad14,10"] || [deviceString isEqualToString:@"iPad14,11"]) return @"iPad Air 13-inch (M2)";
    
    if ([deviceString isEqualToString:@"iPad2,5"] || [deviceString isEqualToString:@"iPad2,6"] || [deviceString isEqualToString:@"iPad2,7"]) return @"iPad Mini";
    if ([deviceString isEqualToString:@"iPad4,4"] || [deviceString isEqualToString:@"iPad4,5"] || [deviceString isEqualToString:@"iPad4,6"]) return @"iPad Mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"] || [deviceString isEqualToString:@"iPad4,8"] || [deviceString isEqualToString:@"iPad4,9"]) return @"iPad Mini 3";
    if ([deviceString isEqualToString:@"iPad5,1"] || [deviceString isEqualToString:@"iPad5,2"]) return @"iPad Mini 4";
    if ([deviceString isEqualToString:@"iPad11,1"] || [deviceString isEqualToString:@"iPad11,2"]) return @"iPad Mini 5";
    if ([deviceString isEqualToString:@"iPad14,1"] || [deviceString isEqualToString:@"iPad14,2"]) return @"iPad Mini 6";
    
    
    if ([deviceString isEqualToString:@"iPad6,3"] || [deviceString isEqualToString:@"iPad6,4"]) return @"iPad Pro 9.7-inch";
    if ([deviceString isEqualToString:@"iPad7,3"] || [deviceString isEqualToString:@"iPad7,4"]) return @"iPad Pro 10.5-inch";
    if ([deviceString isEqualToString:@"iPad8,1"] || [deviceString isEqualToString:@"iPad8,2"] || [deviceString isEqualToString:@"iPad8,3"] || [deviceString isEqualToString:@"iPad8,4"]) return @"iPad Pro 11-inch";
    if ([deviceString isEqualToString:@"iPad8,9"] || [deviceString isEqualToString:@"iPad8,10"]) return @"iPad Pro 11-inch 2";
    if ([deviceString isEqualToString:@"iPad13,4"] || [deviceString isEqualToString:@"iPad13,5"] || [deviceString isEqualToString:@"iPad13,6"] || [deviceString isEqualToString:@"iPad13,7"]) return @"iPad Pro 11-inch 3";
    if ([deviceString isEqualToString:@"iPad14,3"] || [deviceString isEqualToString:@"iPad14,4"]) return @"iPad Pro 11-inch (M2)";
    if ([deviceString isEqualToString:@"iPad16,3"] || [deviceString isEqualToString:@"iPad16,4"]) return @"iPad Pro 11-inch (M4)";
    if ([deviceString isEqualToString:@"iPad6,7"] || [deviceString isEqualToString:@"iPad6,8"]) return @"iPad Pro 12.9-inch";
    if ([deviceString isEqualToString:@"iPad7,1"] || [deviceString isEqualToString:@"iPad7,2"]) return @"iPad Pro 12.9-inch 2";
    if ([deviceString isEqualToString:@"iPad8,5"] || [deviceString isEqualToString:@"iPad8,6"] || [deviceString isEqualToString:@"iPad8,7"] || [deviceString isEqualToString:@"iPad8,8"]) return @"iPad Pro 12.9-inch 3";
    if ([deviceString isEqualToString:@"iPad8,11"] || [deviceString isEqualToString:@"iPad8,12"]) return @"iPad Pro 12.9-inch 4";
    if ([deviceString isEqualToString:@"iPad13,8"] || [deviceString isEqualToString:@"iPad13,9"] || [deviceString isEqualToString:@"iPad13,10"] || [deviceString isEqualToString:@"iPad13,11"]) return @"iPad Pro 12.9-inch 5";
    if ([deviceString isEqualToString:@"iPad14,5"] || [deviceString isEqualToString:@"iPad14,6"]) return @"iPad Pro 12.9-inch (M2)";
    if ([deviceString isEqualToString:@"iPad16,5"] || [deviceString isEqualToString:@"iPad16,6"]) return @"iPad Pro 13-inch (M4)";
    return @"";
}

#pragma mark - 系统版本
+(NSInteger)numbericOSVersion {
    NSString *OSVersion = [[UIDevice currentDevice] systemVersion];
    NSArray *OSVersionArr = [OSVersion componentsSeparatedByString:@"."];
    
    NSInteger numbericOSVersion = 0;
    NSInteger pos = 0;
    
    while ([OSVersionArr count] > pos && pos < 3) {
        numbericOSVersion += ([[OSVersionArr objectAtIndex:pos] integerValue] * pow(10, (4 - pos * 2)));
        pos++;
    }
    
    return numbericOSVersion;
}

#pragma mark - 比较当前系统版本与目标版本之间的大小关系
+ (NSComparisonResult)compareSystemVersion:(NSString *)currentVersion toVersion:(NSString *)targetVersion {
    return [currentVersion compare:targetVersion options:NSNumericSearch];
}

#pragma mark - 判断当前系统是否至少为指定版本
+ (BOOL)isCurrentSystemAtLeastVersion:(NSString *)targetVersion {
    return [self compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedSame || [self compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedDescending;
}

#pragma mark - 判断当前系统是否低于指定版本
+ (BOOL)isCurrentSystemLowerThanVersion:(NSString *)targetVersion {
    return [self compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedAscending;
}


#pragma mark - JSON解析
+(NSDictionary *)jsonData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&error];
    if (error) {
        LOGI(@"数据解析失败 %@", error);
        return nil;
    }
    return json;
}

#pragma mark - 数据字典
+(NSData *)dataFromDictionary:(NSDictionary *)dic {
    
    if (!dic) return nil;
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:0
                                                         error:&error];
    if (error) {
        LOGI(@"字典转JSON失败: %@", error);
        return nil;
    }
    return jsonData;
}

#pragma mark - 字典转 Plist 数据
+(NSData *)plistDataFromDictionary:(NSDictionary *)dic {
    
    // 将字典转换为二进制格式的NSData
    NSError *error;
    NSData *binaryData = [NSPropertyListSerialization dataWithPropertyList:dic
                                                                    format:NSPropertyListBinaryFormat_v1_0
                                                                   options:0
                                                                     error:&error];
    if (error) {
        LOGI(@"转换失败%@",error);
        return [[NSData alloc] init];
    } else {
        return binaryData;
    }
}


#pragma mark - 获取应用icon 图标
+(UIImage *)getAppIconForIdentifier:(NSString *)identifier
{
    Class UIImageClass = objc_getClass("UIImage");
    SEL selector = sel_registerName("_applicationIconImageForBundleIdentifier:format:scale:");
    if ([UIImageClass respondsToSelector:selector]) {
        IMP imp = [UIImageClass methodForSelector:selector];
        UIImage *(*func)(id, SEL, id, int, double) = (void *)imp;
        UIImage *icon = func(UIImageClass, selector, identifier, 10, 2.0f);
        return icon;
    }
    return nil;
}
@end

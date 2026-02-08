//
//  YKDeviceManager.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2026/2/3.
//

// 导入底层网络、系统内核及 IOKit 框架头文件
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <IOKit/IOKitKeys.h>
#import <IOKit/IOKitLib.h>
#import "YKDeviceManager.h"


// --- 第一部分：Core Telephony (移动通讯相关信息) ---
// 这部分通过私有函数与 CommCenter 通信，获取 SIM 卡和蜂窝网络硬件信息
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct CTResult {
    int flag;
    int a;
} CTResult;

// 声明私有函数：创建电信服务器连接
OBJC_EXTERN struct CTServerConnection *_CTServerConnectionCreate(CFAllocatorRef, int (*)(void *, CFStringRef, CFDictionaryRef, void *), int *);
// 声明私有函数：拷贝移动设备信息（IMEI, ICCID 等）
OBJC_EXTERN void _CTServerConnectionCopyMobileEquipmentInfo(CTResult *status, CFTypeRef connection, CFMutableDictionaryRef *equipmentInfo);

// 回调函数，通常传空即可
static int callback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
    return 0;
}

// 声明私有 Key 常量（这些常量定义在 CoreTelephony 内部）
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoERIVersion;
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoICCID;
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoIMEI;
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoMEID;
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoPRLVersion;
OBJC_EXTERN const NSString * const kCTMobileEquipmentInfoIMSI;



@implementation YKDeviceManager


/** 通用私有方法：根据指定的 Key 获取移动设备信息 */
+(NSString *)yk_mobileDeviceInfoForKey:(const NSString *)key {
    NSString *retVal = nil;
    // 1. 创建私有连接
    CFTypeRef ctsc = _CTServerConnectionCreate(kCFAllocatorDefault, callback, NULL);
    if (ctsc) {
        struct CTResult result;
        CFMutableDictionaryRef equipmentInfo = nil;
        // 2. 获取设备信息字典
        _CTServerConnectionCopyMobileEquipmentInfo(&result, ctsc, &equipmentInfo);
        if (equipmentInfo) {
            // 从字典中提取对应的值
            retVal = [NSString stringWithString:CFDictionaryGetValue(equipmentInfo, (__bridge const void *)(key))];
            CFRelease(equipmentInfo);
        }
        CFRelease(ctsc);
    }
    return retVal;
}


/**
 * 获取扩展漫游指示器 (ERI) 版本号
 * ERI 用于在 CDMA 网络中显示设备当前的漫游状态（如显示“漫游”图标或特定的运营商名称）。
 */
+ (NSString *)yk_ERIVersion {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoERIVersion];
}

/**
 * 获取 SIM 卡唯一识别码 (ICCID - Integrated Circuit Card Identifier)
 * 这是固化在物理 SIM 卡上的 20 位数字，是 SIM 卡的“身份证号”，用于识别特定的物理卡片。
 */
+ (NSString *)yk_ICCID {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoICCID];
}

/**
 * 获取国际移动设备识别码 (IMEI - International Mobile Equipment Identity)
 * 手机的硬件序列号，全球唯一。这是识别移动电话硬件设备最常用的 ID。
 */
+ (NSString *)yk_IMEI {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoIMEI];
}

/**
 * 获取国际移动用户识别码 (IMSI - International Mobile Subscriber Identity)
 * 储存在 SIM 卡中，用于向电信网络标识合法的移动用户。运营商通过它来锁定用户的手机号和套餐信息。
 */
+(NSString *)yk_IMSI {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoIMSI];
}

/**
 * 获取移动设备识别码 (MEID - Mobile Equipment Identifier)
 * 类似于 IMEI，但主要用于 CDMA 制式的手机（如早期的电信版 iPhone）。它是 5 格式的全球唯一识别码。
 */
+ (NSString *)yk_MEID {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoMEID];
}

/**
 * 获取首选漫游列表 (PRL - Preferred Roaming List) 版本号
 * PRL 是一张存储在手机里的表，决定了手机在搜索网络时，应该按什么优先级连接哪些运营商的基站。
 */
+ (NSString *)yk_PRLVersion {
    return [self yk_mobileDeviceInfoForKey:kCTMobileEquipmentInfoPRLVersion];
}



@end

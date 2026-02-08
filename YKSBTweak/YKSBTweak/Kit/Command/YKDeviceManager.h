//
//  YKDeviceManager.h
//  YKSBTweak
//
//  Created by liuxiaobin on 2026/2/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 设备信息管理类
@interface YKDeviceManager : NSObject


/**
 * 获取扩展漫游指示器 (ERI) 版本号
 * ERI 用于在 CDMA 网络中显示设备当前的漫游状态（如显示“漫游”图标或特定的运营商名称）。
 */
+(NSString *)yk_ERIVersion;

/**
 * 获取 SIM 卡唯一识别码 (ICCID - Integrated Circuit Card Identifier)
 * 这是固化在物理 SIM 卡上的 20 位数字，是 SIM 卡的“身份证号”，用于识别特定的物理卡片。
 */
+(NSString *)yk_ICCID;


/**
 * 获取国际移动设备识别码 (IMEI - International Mobile Equipment Identity)
 * 手机的硬件序列号，全球唯一。这是识别移动电话硬件设备最常用的 ID。
 */
+(NSString *)yk_IMEI;


/**
 * 获取国际移动用户识别码 (IMSI - International Mobile Subscriber Identity)
 * 储存在 SIM 卡中，用于向电信网络标识合法的移动用户。运营商通过它来锁定用户的手机号和套餐信息。
 */
+(NSString *)yk_IMSI;


/**
 * 获取移动设备识别码 (MEID - Mobile Equipment Identifier)
 * 类似于 IMEI，但主要用于 CDMA 制式的手机（如早期的电信版 iPhone）。它是 5 格式的全球唯一识别码。
 */
+(NSString *)yk_MEID;


/**
 * 获取首选漫游列表 (PRL - Preferred Roaming List) 版本号
 * PRL 是一张存储在手机里的表，决定了手机在搜索网络时，应该按什么优先级连接哪些运营商的基站。
 */
+(NSString *)yk_PRLVersion;
@end

NS_ASSUME_NONNULL_END

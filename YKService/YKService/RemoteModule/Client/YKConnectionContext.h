//
//  YKConnectionContext.h
//  Created on 2026/1/30
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 连接介质类型
///
/// 表示设备之间建立连接所使用的物理 / 传输介质
typedef NS_ENUM(NSInteger, YKConnectionMedium) {
    /// 通过 USB 建立连接
    YKConnectionMediumUSB,
    
    /// 通过 Wi-Fi 建立连接
    YKConnectionMediumWiFi,
};


/// Wi-Fi 连接建立方式
///
/// 仅在连接介质为 Wi-Fi 时有效
typedef NS_ENUM(NSInteger, YKWiFiConnectionMode) {
    /// 被动连接
    /// 由对端通过 UDP 广播 / 下发信息触发，不涉及扫码
    YKWiFiConnectionModePassive,
    
    /// 主动连接
    /// 通过扫描二维码等方式主动发起连接
    YKWiFiConnectionModeActive,
};


/// 网络作用范围
///
/// 用于区分当前连接所处的网络环境
typedef NS_ENUM(NSInteger, YKNetworkScope) {
    /// 局域网环境（LAN）
    /// 设备处于同一局域网内
    YKNetworkScopeLAN,
    
    /// 广域网环境（WAN）
    /// 通过公网或跨网段建立连接
    YKNetworkScopeWAN,
};


/// 连接上下文
///
/// 描述一次连接的真实语义信息，
/// 包括连接介质、Wi-Fi 建链方式及网络环境。
///
/// 该对象用于内部建模，
/// 服务端所需的协议字段应由此上下文映射生成。
@interface YKConnectionContext : NSObject

/// 连接介质（USB / Wi-Fi）
@property (nonatomic) YKConnectionMedium medium;

/// Wi-Fi 连接方式（被动 / 主动）
///
/// 当 medium != YKConnectionMediumWiFi 时，该字段可忽略
@property (nonatomic) YKWiFiConnectionMode wifiMode;

/// 网络作用范围（局域网 / 广域网）
///
/// 通常仅在 Wi-Fi 主动连接（扫码）时有意义
@property (nonatomic) YKNetworkScope networkScope;

/// 是否已向用户展示过相关提示
///
/// 用于标记当前连接流程中，
/// 是否已经弹出过提示 / 引导 / 风险确认等 UI，
/// 以避免重复提示。
@property(nonatomic, assign) BOOL hasShownPrompt;
@end


NS_ASSUME_NONNULL_END

//
//  YKConstants.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <Foundation/Foundation.h>

// 包名
#define YK_BID @"com.sky.ykpro"

// WIFI 端口扫描
#define YK_WIFI_LISTEN_PORT 32838

// USB 端口
#define YK_USB_LISTEN_PORT 32839

// 本地地址
#define YK_USB_LOCALHOST @"127.0.0.1"

/// 请求头标签位
#define YK_SOCKET_HEADER_TAG 0x1000

/// 请求BODY标签位
#define YK_SOCKET_BODY_TAG 0x2000

// 数据头长度
#define YK_DATA_HEADER_SIZE 12

// 接受端魔术数
#define YK_MAGIC_RECEIVER   0xc6e8f3de9a654d6bULL

// 发送端魔术数
#define YK_MAGIC_SENDER     0xb7c2e0f542a39a3eULL

// 定义文件数据块大小为 64KB
#define YK_FILE_CHUNKSIZE  65536

// 下载文件保存路径
#define YK_DOWNLOADS_PATH @"/var/mobile/Library/YKApp/Downloads/Tmp/"

// 二维码扫描连接错误提示
#define YK_SCAN_QRCODE_ERROR_MSG @"该二维码不是远控Pro的连接二维码"

// 崩溃日志地址
#define kCrashLogs @"/var/mobile/Library/YKApp/CrashLogs/"

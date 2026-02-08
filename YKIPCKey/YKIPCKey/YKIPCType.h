//
//  YKIPCType.h
//  YKIPCKey
//
//  Created by liuxiaobin on 2025/9/17.
//


//============================================================
// PORT端口Key
//============================================================
#define NOTIFY_PORT_YK_SRPINGBOARD @"com.sky.yk.springboard.notify"//Springboard端口
#define NOTIFY_PORT_YK_SERVICE @"com.sky.yk.service.notify"//服务端口
#define NOTIFY_PORT_YK_APP @"com.sky.yk.app.notify"//App端口
#define NOTIFY_PORT_YK_LAUNCHD @"com.sky.yk.launchd.notify"//守护进程端口
#define NOTIFY_PORT_YK_AUDIO @"com.sky.yk.audio.notify"//音频进程端口
#define NOTIFY_PORT_YK_UIKIT @"com.sky.yk.uikit.notify"//UIKit端口



//============================================================
// 枚举Key(谁处理谁定义枚举的原则)
//============================================================
typedef NS_ENUM(NSInteger, YKSBNotificationType) {
    YKSBNotificationTypeUnknown = -1,                      // 未知类型
    YKSBNotificationTypeToast = 1,                         // 吐司
    YKSBNotificationTypeUUID,                              // 唯一标识
    YKSBNotificationTypeSBInit,                            // SB初始化
    YKSBNotificationTypeInstallDEB,                        // 安装Deb
    YKSBNotificationTypeGetPasteboard,                     // 获取到剪切板数据
    YKSBNotificationTypeSetPasteboard,                     // 设置剪切板数据
    YKSBNotificationTypeGetFrontBid,                       // 获取前台执行的App
    YKSBNotificationTypeSetDeviceName,                     // 修改设备名称
    YKSBNotificationTypeHomeScreen,                        // 点击Home
    YKSBNotificationTypeKillApp,                           // 杀掉App
    YKSBNotificationTypeShowCenterController,              // 显示控制中心
    YKSBNotificationTypeAppDeviceInfo,                     // App信息
    YKSBNotificationTypeCopyToClipboard,                   // 拷贝输入文本
    YKSBNotificationTypeReStart,                           // 重启服务
    YKSBNotificationTypeAppSwitcher,                       // App后台进程切换
    YKSBNotificationTypeGetAppPath,                        // 获取App数据路径
    YKSBNotificationTypeAirPlay,                           // AirPlay
    YKSBNotificationTypePreferences,                       // 打开设置App
    YKSBNotificationTypeScanQrcode,                        // 扫描二维码
    YKSBNotificationTypeGetAudioVersion,                   // 获取音频版本号
    YKSBNotificationTypeAudioDylibInject,                  // 发送音频重新注入(一定要等Springboard启动后，不然会跟其他的插件冲突，然后导致安全模式)
    YKSBNotificationTypeGetAudioPort,                      // 获取音频端口
    YKSBNotificationTypeConnectAudio,                      // 连接音频
    YKSBNotificationTypeAudioPlay,                         // 音频处理
    YKSBNotificationTypeRecordAnimation,                   // 录制倒计时动画(开始、完成)
    YKSBNotificationTypeRecordAnimationComplete,           // 录制倒计时动画完成
    YKSBNotificationTypeServiceEnabled,                    // 服务是否启用
    YKSBNotificationTypeKillBid,                           // 关闭指定App
    YKSBNotificationTypeUnInstallDEB,                      // 卸载Deb
    YKSBNotificationTypeDeviceNameChanged,                 // 设备名称主动改变通知
    YKSBNotificationTypeSetWifiEnable,                     // 设置WIFI是否启用
    YKSBNotificationTypeGetWifiEnable,                     // 获取WIFI是否启用
    YKSBNotificationTypeSetCellularDataEnable,             // 设置蜂窝是否启用
    YKSBNotificationTypeGetCellularDataEnable,             // 获取蜂窝是否启用
    YKSBNotificationTypeSetBluetoothEnable,                // 设置蓝牙是否启用
    YKSBNotificationTypeGetBluetoothEnable,                // 获取蓝牙是否启用
    YKSBNotificationTypeScreenUnlock,                      // 解锁屏幕
    YKSBNotificationTypeIsScreenLocked,                    // 是否锁定屏幕
    YKSBNotificationTypeLockOrientation,                   // 锁定屏幕旋转
    YKSBNotificationTypeUnlockOrientation,                 // 解锁屏幕旋转
};




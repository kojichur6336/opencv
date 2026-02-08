//
//  YKSBIPCController.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/17.
//

#import "YKSBToast.h"
#import "YKSBLogger.h"
#import "YKCommand.h"
#import <YKXPC/YKXPC.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "YKDeviceManager.h"
#import <YKIPCKey/YKIPCKey.h>
#import "YKSBIPCController.h"
#import "YKSBRecordViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#define yk_startMessageThread               A85562x836ebcc9a5aed7a2bc846a706671
#define yk_sendSBInit                       B874ea1b232x06a94f3ac238d34a3f02563
#define yk_messageThreadMain                C1a56672sdc6ea28a4dc8127d43c6a37a0e


@interface YKSBIPCController()
@property(nonatomic, strong) dispatch_source_t timer;//定时器用来切换屏幕亮度
@property(nonatomic, strong) NSThread *messageThread; // 独立消息处理线程
@property(nonatomic, strong) YKCFMessagePortLocal *messagePortLocal;//本地进程通讯服务器
@property(nonatomic, strong) YKCFMessagePortRemote *servicePortRemote;//服务远程连接消息
@end

@implementation YKSBIPCController

-(instancetype)init {
    self = [super init];
    if (self) {
        [self yk_startMessageThread];
        [self yk_sendSBInit];
    }
    return self;
}

//============================================================
// 进程通讯处理
//============================================================
#pragma mark - 启动独立线程
-(void)yk_startMessageThread {
    
    // 切换到主线程去创建线程
    dispatch_async(dispatch_get_main_queue(), ^{

        self.messageThread = [[NSThread alloc] initWithTarget:self selector:@selector(yk_messageThreadMain) object:nil];
        [self.messageThread start];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        
    });
}

#pragma mark - NSThread 主函数
-(void)yk_messageThreadMain {
    
    @autoreleasepool {
        
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        
        // 创建本地消息端口
        __weak typeof(self) weakSelf = self;
        self.messagePortLocal = [[YKCFMessagePortLocal alloc] initWithName:NOTIFY_PORT_YK_SRPINGBOARD runLoop:runLoop syncHandler:^NSDictionary * _Nullable(int cmd, NSDictionary * _Nullable msgData) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return nil;
            
            LOGI(@"消息线程收到消息 cmd: %d, data: %@", cmd, msgData);
            
            __block NSDictionary *callback = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                switch (cmd) {
                    case YKSBNotificationTypeToast:
                    {
                        NSString *text = msgData[@"text"];
                        [YKSBToast showMessage:text];
                    }
                        break;
                    case YKSBNotificationTypeUUID:
                    {
                        callback = @{@"uuid": [YKCommand yk_udid]};
                    }
                        break;
                    case YKSBNotificationTypeGetFrontBid:
                    {
                        callback = @{@"id": [YKCommand yk_frontAppBID]};
                    }
                        break;
                    case YKSBNotificationTypeSetDeviceName: {
                        [YKCommand yk_setDeviceName:msgData[@"text"]];
                    }
                        break;
                    case YKSBNotificationTypeHomeScreen: {
                        [YKCommand yk_homeScreen];
                    }
                        break;
                    case YKSBNotificationTypeKillApp: {
                        NSString *bid = msgData[@"bid"];
                        int flag = [msgData[@"flag"] intValue];
                        [YKCommand yk_killAppWithBid:bid flag:flag];
                    }
                        break;
                    case YKSBNotificationTypeShowCenterController: {
                        [YKCommand yk_showCenterController];
                    }
                        break;
                    case YKSBNotificationTypeAppSwitcher: {
                        [YKCommand yk_appSwitcher];
                    }
                        break;
                    case YKSBNotificationTypeGetAppPath: {
                        
                        int type = [msgData[@"type"] intValue];
                        NSString *identifier = msgData[@"id"];
                        if (type == 1) {
                            
                            NSString *path = [YKCommand yk_getAppDataPath:identifier];
                            callback = @{@"path": path};
                            
                        } else if (type == 2) {
                            
                            NSString *path = [YKCommand yk_getAppBundlePath:identifier];
                            callback = @{@"path": path};
                        } else {
                            
                            NSString *path = [YKCommand yk_getGroupContainerPath:identifier];
                            callback = @{@"path": path};
                        }
                    }
                        break;
                    case YKSBNotificationTypeRecordAnimation: {
                        
                        BOOL isStart = [msgData[@"isStart"] boolValue];
                        if (isStart) {
                            
                            [YKSBRecordViewController show:^{
                                [weakSelf.servicePortRemote sendMessage:YKSBNotificationTypeRecordAnimationComplete];
                            }];
                        } else {
                            [YKSBRecordViewController hidden];
                        }
                    }
                        break;
                    case YKSBNotificationTypeKillBid: {
                        
                        NSString *bid = msgData[@"bid"];
                        [YKCommand yk_killAppWithBid: bid flag:1];
                    }
                        break;
                    case YKSBNotificationTypeGetWifiEnable: {
                        BOOL enable = [YKCommand yk_isWiFiEnabled];
                        callback = @{@"enable": @(enable)};
                    }
                        break;
                    case YKSBNotificationTypeSetWifiEnable: {
                        
                        BOOL enable = [msgData[@"enable"] boolValue];
                        [YKCommand yk_setWifiEnable:enable];
                    }
                        break;
                    case YKSBNotificationTypeSetCellularDataEnable: {
                        
                        BOOL enable = [msgData[@"enable"] boolValue];
                        [YKCommand yk_setCellularDataEnable:enable];
                    }
                        break;
                    case YKSBNotificationTypeGetCellularDataEnable: {
                        BOOL enable = [YKCommand yk_isCellularDataEnable];
                        callback = @{@"enable": @(enable)};
                    }
                        break;
                    case YKSBNotificationTypeSetBluetoothEnable: {
                        BOOL enable = [msgData[@"enable"] boolValue];
                        [YKCommand yk_setBluetoothEnable:enable];
                    }
                    break;
                    case YKSBNotificationTypeGetBluetoothEnable: {
                        BOOL enable = [YKCommand yk_isBluetoothEnabled];
                        callback = @{@"enable": @(enable)};
                    }
                        break;
                    case YKSBNotificationTypeScreenUnlock:
                    {
                        NSString *passcode = msgData[@"passcode"];
                        [YKCommand yk_unLockScreen:passcode];
                    }
                        break;
                    case YKSBNotificationTypeIsScreenLocked: {
                        BOOL enable = [YKCommand yk_isScreenLocked];
                        callback = @{@"enable": @(enable)};
                    }
                        break;
                        
                    case YKSBNotificationTypeLockOrientation: {
                        [YKCommand yk_lockOrientation];
                    }
                        break;
                    case YKSBNotificationTypeUnlockOrientation: {
                        [YKCommand yk_unlockOrientation];
                    }
                        break;
                    default:
                        break;
                }
            });
            return callback;
        }];
        CFRunLoopRun(); // 启动线程 RunLoop，持续监听
    }
}



#pragma mark - 发送初始化
-(void)yk_sendSBInit {
    
    YKCFMessagePortErrorCode result = [self.servicePortRemote sendMessage:@{} cmd:YKSBNotificationTypeSBInit];
    if (result != YKCFMessagePortErrorSuccess)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self yk_sendSBInit];
        });
    }
}



#pragma mark - lazy
-(YKCFMessagePortRemote *)servicePortRemote {
    if (!_servicePortRemote) {
        _servicePortRemote = [[YKCFMessagePortRemote alloc] initWithName:NOTIFY_PORT_YK_SERVICE];
    }
    return _servicePortRemote;
}
@end


#pragma clang diagnostic pop

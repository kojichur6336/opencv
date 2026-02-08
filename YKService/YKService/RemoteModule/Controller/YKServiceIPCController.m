//
//  YKServiceIPCController.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <dlfcn.h>
#import "YKSimulator.h"
#import <YKXPC/YKXPC.h>
#import "YKServiceTool.h"
#import "YKServiceLogger.h"
#import <YKIPCKey/YKIPCKey.h>
#import "YKApplicationManager.h"
#import "YKServiceIPCController.h"

#define ykipc_messagePortLocal                          A78bxf158423f757fde6e6f0d5785637284
#define ykipc_audioDylibInject                          Bdc492s4906110f65f0bba69a9dd283b9dd
#define ykipc_isSpringboardRestartRequired              C8120b102d899a913806fbf83b5d81631cd
#define ykipc_addNotication                             D394bf3838dx33d1773233e518707eccd04
#define ykipc_startMessageThread                        Ef57f9cc77c01ef892bb2a6e91e282eb01d
#define ykipc_isChoicy                                  Fa663c8c9ba2df652ae00c5bf6c783b1506
#define ykipc_messageThreadMain                         Gfcac232830aef80e69f0f5b612a948acf3

@interface YKServiceIPCController()
@property(nonatomic, strong) NSThread *messageThread; // 独立消息处理线程
@property(nonatomic, strong) YKCFMessagePortLocal *ykipc_messagePortLocal;//本地进程通讯服务器
@property(nonatomic, strong) YKCFMessagePortRemote *springboardPortRemote;//Springboard客户端通讯
@property(nonatomic, assign) BOOL ykipc_isSpringboardRestartRequired;//是否需要重启Springboard
@property(nonatomic, copy) void (^recordAnimationCompletionBlock)(void);  //录制倒计时动画完成block
@end


@implementation YKServiceIPCController

+ (instancetype)sharedManager {
    static YKServiceIPCController *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YKServiceIPCController alloc] init];
    });
    return manager;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self ykipc_addNotication];
        [self ykipc_startMessageThread];
    }
    return self;
}


#pragma mark - 显示消息
-(void)ykipc_showLogsMessage:(NSString *)message {
    
    [self.springboardPortRemote sendMessage:@{@"text": message} cmd:YKSBNotificationTypeToast];
}

#pragma mark - 安装Deb路径
-(void)ykipc_installDeb:(NSString *)path completion:(void (^)(BOOL, NSString *))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL success = NO;
        NSString *msg;
        NSDictionary *result = [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_LAUNCHD cmd:YKSBNotificationTypeInstallDEB data:@{@"path": path}];
        if (result) {
            success = [result[@"status"] boolValue];
            msg = result[@"msg"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, msg);
        });
    });
}

#pragma mark - 卸载Deb
-(void)yjipc_uninstallDeb:(NSString *)bid completion:(void (^)(BOOL, NSString *))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL success = NO;
        NSString *msg;
        NSDictionary *result = [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_LAUNCHD cmd:YKSBNotificationTypeUnInstallDEB data:@{@"bid": bid}];
        if (result) {
            success = [result[@"status"] boolValue];
            msg = result[@"msg"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, msg);
        });
    });
}

#pragma mark - 获取唯一标识
-(NSString *)ykipc_uuid {
    
    YKCFMessagePortSyncResult *result = [self.springboardPortRemote sendSyncMessage:YKSBNotificationTypeUUID];
    if (result.errorCode == YKCFMessagePortErrorSuccess && result.replyData)
    {
        self.ykipc_isSpringboardRestartRequired = NO;
        return result.replyData[@"uuid"];
    } else {
        
        typedef CFPropertyListRef(*MGCopyAnswerFunc)(CFStringRef);
        void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
        MGCopyAnswerFunc mgcopy = dlsym(gestalt, "MGCopyAnswer");
        CFStringRef UDID = mgcopy(CFSTR("UniqueDeviceID"));
        NSString *uid = (__bridge NSString * _Nonnull)(UDID);
        self.ykipc_isSpringboardRestartRequired = YES;
        return  uid;
    }
}

#pragma mark - 重启Springboard 提示
-(NSString *)ykipc_springBoardMsg {
    
    if (self.ykipc_isSpringboardRestartRequired) {
        return @"SpringBoard 插件注入未生效\n"
        "1. 请点击“重启”尝试激活；\n"
        "2. 若无效，请检查是否被屏蔽插件拦截；\n"
        "3. 或移除越狱后重新越狱。";
    } else {
        return @"";
    }
}

#pragma mark - 屏幕解锁
-(void)ykipc_screenUnlock {
    
    if (self.springboardPortRemote) {
        [self.springboardPortRemote sendMessage:@{@"passcode":@""} cmd:YKSBNotificationTypeScreenUnlock];
    } else {
        [YKSimulator menuPress];
        usleep(1000 * 1000);
        [YKSimulator menuPress];
    }
}

#pragma mark - 获取前台执行的App
-(NSString *)ykipc_getFrontBid {
    
    YKCFMessagePortSyncResult *result = [self.springboardPortRemote sendSyncMessage:YKSBNotificationTypeGetFrontBid];
    if (result.errorCode == YKCFMessagePortErrorSuccess && result.replyData)
    {
        return result.replyData[@"id"];
    } else {
        return nil;
    }
}



#pragma mark - 是否被屏蔽了
-(BOOL)ykipc_isChoicy {
    
    if (self.ykipc_isSpringboardRestartRequired) {
        
        NSString *choicySBPath = [YKServiceTool conversionJBRoot:@"/Library/MobileSubstrate/DynamicLibraries/ChoicySB.dylib"];
        NSString *ChoicyPath = [YKServiceTool conversionJBRoot:@"/Library/MobileSubstrate/DynamicLibraries/   Choicy.dylib"];
        NSFileManager *fm = [NSFileManager defaultManager];
        
        BOOL exist1 = [fm fileExistsAtPath:choicySBPath];
        BOOL exist2 = [fm fileExistsAtPath:ChoicyPath];
        if (exist1 || exist2)
        {
            return YES;
        } else {
            return NO;
        }
        
    } else {
        return NO;
    }
}

#pragma mark - 屏蔽了
-(NSString *)ykipc_choicyMsg {
    
    if (self.ykipc_isChoicy) {
        return @"您使用choicy插件屏蔽了远控Pro插件, 请到 设置(App) -> 往下滑动找到 Choicy，点击重置首选项,然后回到远控ProApp。点击重启服务, 即可正常使用";
    } else {
        return @"";
    }
}


#pragma mark - 修改名称
-(void)ykipc_setDeviceName:(NSString *)name {
    [self.springboardPortRemote sendMessage:@{@"text": name} cmd:YKSBNotificationTypeSetDeviceName];
}

#pragma mark - 回到首页
-(void)ykipc_homeScreen {
    
    if (self.springboardPortRemote) {
        [self.springboardPortRemote sendMessage:YKSBNotificationTypeHomeScreen];
    } else {
        [YKSimulator menuPress];
    }
}

#pragma mark - 关闭所有后台App
-(void)ykipc_killAllApp {
    [self.springboardPortRemote sendMessage:@{@"bid": @"*", @"flag": @(1)} cmd:YKSBNotificationTypeKillApp];
}

#pragma mark - 显示控制中心
-(void)ykipc_showCenterController {
    [self.springboardPortRemote sendMessage:YKSBNotificationTypeShowCenterController];
}

#pragma mark - 更新连接状态
-(void)ykipc_updateConnect {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSArray *connectedServices = [self.delegate ykipc_serviceIPCControllerConnectedServices:self];
    dic[@"isServiceEnabled"] = @([self.delegate ykipc_serviceIPCControllerServiceEnabled:self]);
    dic[@"connectedServices"] = connectedServices;
    dic[@"deviceID"] = self.ykipc_uuid;
    NSString *environment;
    switch ([YKServiceTool jbType]) {
        case 1:
        {
            environment = @"有根";
        }
            break;
        case 2: {
            environment = @"无根";
        }
            break;
        case 3: {
            environment = @"隐根";
        }
            break;
        default: break;
    }
    dic[@"environment"] = environment;
    dic[@"deviceName"] = UIDevice.currentDevice.name;//设备名称
    dic[@"ip"] = [YKServiceTool getIpAddresses];
    
    //判断是否被Choicy屏蔽SpringBoard
    if (self.ykipc_isChoicy)
    {
        dic[@"choicy"] = @(YES);
        dic[@"choicyMsg"] = self.ykipc_choicyMsg;
    } else {
        dic[@"choicy"] = @(NO);
    }
    
    dic[@"isSpringboardRestartRequired"] = @(self.ykipc_isSpringboardRestartRequired);
    dic[@"springboardMsg"] = self.ykipc_springBoardMsg;
    
    if ([YKServiceTool isCurrentSystemLowerThanVersion:@"14.0"] && [@[@"iPhone XS", @"iPhone XS Max", @"iPhone XR", @"iPhone 11",@"iPhone 11 Pro",@"iPhone SE (2nd generation)"] containsObject:[YKServiceTool platform]]) {
        dic[@"supportsThisDevice"] = @(NO);
        dic[@"supportsThisDeviceMsg"] = [NSString stringWithFormat:@"该设备型号(%@), 该系统(%@)不支持该软件", [YKServiceTool platform],[[UIDevice currentDevice] systemVersion]];
    } else {
        dic[@"supportsThisDevice"] = @(YES);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_APP cmd:YKSBNotificationTypeAppDeviceInfo data:dic];
    });
}


#pragma mark - 设置WIFI是否开关
-(void)ykipc_setWifiEnable:(BOOL)enable {
    [self.springboardPortRemote sendMessage:@{@"enable": @(enable)} cmd:YKSBNotificationTypeSetWifiEnable];
}

#pragma mark - 设置蜂窝数据开关
-(void)ykipc_setCellularDataEnable:(BOOL)enable
{
    [self.springboardPortRemote sendMessage:@{@"enable": @(enable)} cmd:YKSBNotificationTypeSetCellularDataEnable];
}


#pragma mark - 获取App数据类型路径
-(NSString *)ykipc_getAppDataPathWithType:(int)type ykipc_identifier:(NSString *)identifier {
    
    YKCFMessagePortSyncResult *result = [self.springboardPortRemote sendSyncMessage:@{@"id": identifier, @"type": @(type)} cmd:YKSBNotificationTypeGetAppPath];
    if (result.replyData) {
        return result.replyData[@"path"];
    } else {
        return nil;
    }
}

#pragma mark - AirPlay切换
-(void)ykipc_airPlaySwitch:(BOOL)isOpen ykipc_airPlayName:(NSString *)airPlayName {
    
    [self.springboardPortRemote sendSyncMessage:@{@"open": @(isOpen), @"name": airPlayName} cmd:YKSBNotificationTypeAirPlay];
}

#pragma mark - 音频播放切换
-(void)ykipc_audioPlaySwitch:(BOOL)isOpen ykipc_deviceName:(NSString *)deviceName {
    [self.springboardPortRemote sendSyncMessage:@{@"open": @(isOpen), @"name": deviceName} cmd:YKSBNotificationTypeAudioPlay];
}


#pragma mark - 扫描回执
-(void)ykipc_scanQrcodeReceipt:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_APP cmd:YKSBNotificationTypeScanQrcode data:@{@"msg": msg}];
    });
}

#pragma mark - 注入版本号
-(void)ykipc_audioDylibInject
{
    //通过SB发送消息过来接受到，然后去判断是否注入过Audio(这样子才不会导致SB崩溃)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        int newVersion = 2;
        BOOL success = NO;
        int version = 0;
        NSDictionary *result = [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_AUDIO cmd:YKSBNotificationTypeGetAudioVersion data:@{} timeout:5];
        if (result) {
            success = YES;
            version = [result[@"version"] intValue];
        }
        
        if (success == NO || (success && newVersion != version))
        {
            LOGI(@"需要重新注入版本不一致，新版本%d, 旧版本是%d", newVersion, version);
            [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_LAUNCHD cmd:YKSBNotificationTypeAudioDylibInject];
        } else {
            LOGI(@"已经注入过Audio，不需要再注入了%d, 版本号是多少%d", success, version);
        }
    });
}

#pragma mark - 获取音频端口
-(void)ykipc_getAudioPort:(void (^)(BOOL, UInt16))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL success = NO;
        UInt16 port = 0;
        NSDictionary *result = [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_AUDIO cmd:YKSBNotificationTypeGetAudioPort data:@{} timeout:5];
        if (result) {
            success = YES;
            port = [result[@"audioPort"] intValue];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, port);
        });
    });
}

#pragma mark - 连接音频
-(void)ykipc_connectAudioWithIP:(NSString *)ip ykipc_port:(UInt16)port completion:(nonnull void (^)(BOOL, NSString * _Nonnull))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL success = NO;
        NSString * msg = @"连接失败";
        NSDictionary *result = [YKNotificationRequest.shared sendRequestWithPort:NOTIFY_PORT_YK_AUDIO cmd:YKSBNotificationTypeConnectAudio data:@{@"ip": ip, @"port": @(port)} timeout:5];
        if (result) {
            success = [result[@"status"] boolValue];
            msg = result[@"msg"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, msg);
        });
    });
}

#pragma mark - 录制开始动画
-(void)ykipc_startRecordAnimation:(void (^)(void))completion
{
    self.recordAnimationCompletionBlock = completion;
    [self.springboardPortRemote sendSyncMessage:@{@"isStart": @(YES)} cmd:YKSBNotificationTypeRecordAnimation];
}

#pragma mark - 停止录制动画
-(void)ykipc_stopRecordAnimation {
    self.recordAnimationCompletionBlock = nil;
    [self.springboardPortRemote sendSyncMessage:@{@"isStart": @(NO)} cmd:YKSBNotificationTypeRecordAnimation];
}


#pragma mark - 关闭执行包名
-(void)ykipc_killWithBid:(NSString *)bid {
    
    [self.springboardPortRemote sendSyncMessage:@{@"bid": bid} cmd:YKSBNotificationTypeKillBid];
}

#pragma mark - 获取是否锁定屏幕
-(int)ykipc_isScreenLocked {
    
    YKCFMessagePortSyncResult *result =
    [self.springboardPortRemote sendSyncMessage:YKSBNotificationTypeIsScreenLocked];
    if (result.errorCode == YKCFMessagePortErrorSuccess && result.replyData) {
        return [result.replyData[@"enable"] boolValue] == YES ? 1 : 2;
    }
    return -1;
}


//============================================================
// 进程通讯处理
//============================================================
#pragma mark - 启动独立线程
-(void)ykipc_startMessageThread {
    
    self.messageThread = [[NSThread alloc] initWithTarget:self selector:@selector(ykipc_messageThreadMain) object:nil];
    [self.messageThread start];
}

-(void)ykipc_messageThreadMain {
    
    @autoreleasepool {
        
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        
        // 创建本地消息端口
        __weak typeof(self) weakSelf = self;
        self.ykipc_messagePortLocal = [[YKCFMessagePortLocal alloc] initWithName:NOTIFY_PORT_YK_SERVICE runLoop:runLoop syncHandler:^NSDictionary * _Nullable(int cmd, NSDictionary * _Nullable msgData) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return nil;
            
            LOGI(@"消息线程收到消息 cmd: %d, data: %@", cmd, msgData);
            switch (cmd)
            {
                case YKSBNotificationTypeSBInit:
                {
                    [weakSelf ykipc_audioDylibInject];
                }
                    break;
                case YKSBNotificationTypeRecordAnimationComplete: {
                    
                    if (weakSelf.recordAnimationCompletionBlock) {
                        weakSelf.recordAnimationCompletionBlock();
                        weakSelf.recordAnimationCompletionBlock = nil;
                    }
                }
                    break;
                default: {
                    LOGI(@"未知命令");
                }
                    break;
            }
            return nil;
        }];
        CFRunLoopRun(); // 启动线程 RunLoop，持续监听
    }
}


//============================================================
// 通知处理
//============================================================
#pragma mark - 添加通知
-(void)ykipc_addNotication {
    
    __weak typeof(self) weakSelf = self;
    [YKNotificationRequest.shared addNotificationWithObserver:self port:NOTIFY_PORT_YK_SERVICE completion:^(NSInteger cmd, NSString * _Nonnull replyID, NSDictionary * _Nonnull data) {
        
        switch (cmd) {
            case YKSBNotificationTypeAppDeviceInfo:
            {
                LOGI(@"收到获取基础信息");
                [weakSelf ykipc_updateConnect];
            }
                break;
            case YKSBNotificationTypeHomeScreen: {
                
                [self ykipc_homeScreen];
                
            }
                break;
            case YKSBNotificationTypePreferences:
            {
                [YKApplicationManager launch:@"com.apple.Preferences"];
            }
                break;
            case YKSBNotificationTypeScanQrcode:
            {
                [weakSelf.delegate ykipc_serviceIPCController:weakSelf ykipc_qrCode:data[@"qrcode"]];
                
            }
                break;
            case YKSBNotificationTypeGetPasteboard: {
                
                NSString *bid = data[@"bundleIdentifier"];
                NSString *appName = data[@"appName"];
                NSDictionary *temResul = [self ykipc_getClipboardContentWaiting:YES];
                NSString *clipText = temResul[@"text"];
                int type = [temResul[@"type"] intValue];
                
                if (clipText.length > 0) {
                    
                    [weakSelf.delegate ykipc_serviceIPCController:weakSelf ykipc_didCopyContent:clipText ykipc_type:type ykipc_appName:appName ykipc_bid:bid];
                } else {
                    LOGI(@"空数据什么都不处理");
                }
            }
                break;
            case YKSBNotificationTypeServiceEnabled: {
                [weakSelf.delegate ykipc_serviceIPCController:weakSelf ykipc_isServiceEnabled:[data[@"isServiceEnabled"] boolValue]];
            }
                break;
            case YKSBNotificationTypeDeviceNameChanged: {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSString *newName = [UIDevice currentDevice].name;
                    [weakSelf.delegate ykipc_serviceIPCController:weakSelf ykipc_deviceNameChanged:newName];
                });
            }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - 获取剪切板的值
-(NSDictionary *)ykipc_getClipboardContentWaiting:(BOOL)shouldWait
{
    
    int type = 1;
    NSString *copyText = @"";
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    do {
        // 1. 尝试获取字符串
        if (pasteboard.string && pasteboard.string.length > 0) {
            copyText = pasteboard.string;
            type = 1;
        }
        // 2. 尝试获取图片
        else if (pasteboard.image) {
            NSData *imageData = UIImagePNGRepresentation(pasteboard.image);
            NSString *base64String = [imageData base64EncodedStringWithOptions:0]; // 建议去掉换行符选项，方便传输
            copyText = base64String;
            type = 2;
        }
        // 3. 尝试获取URL
        else if (pasteboard.URL) {
            copyText = pasteboard.URL.absoluteString;
            type = 3;
        }
        // 4. 尝试获取颜色
        else if (pasteboard.color) {
            CGFloat r, g, b, a;
            [pasteboard.color getRed:&r green:&g blue:&b alpha:&a];
            int red = (int)(r * 255.0);
            int green = (int)(g * 255.0);
            int blue = (int)(b * 255.0);
            int alpha = (int)(a * 255.0);
            copyText = [NSString stringWithFormat:@"#%02X%02X%02X%02X", red, green, blue, alpha];
            type = 4;
        }
        
        // 如果没拿到内容，且需要等待，则休眠后继续
        if (copyText.length == 0 && shouldWait) {
            [NSThread sleepForTimeInterval:0.5];
        }
        
    } while (copyText.length == 0 && shouldWait); // 只有在需要等待且没拿到内容时才循环
    
    return @{@"text": copyText ?: @"", @"type": @(type)};
}



#pragma mark - lazy
-(YKCFMessagePortRemote *)springboardPortRemote
{
    if (!_springboardPortRemote) {
        _springboardPortRemote = [[YKCFMessagePortRemote alloc] initWithName:NOTIFY_PORT_YK_SRPINGBOARD];
    }
    return _springboardPortRemote;
}
@end

//
//  YKServiceRemoteController.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKKeyMap.h"
#import "YKArchive.h"
#import "YKRecorder.h"
#import "YKSimulator.h"
#import "YKConstants.h"
#import "YKKBDManager.h"
#import "YKRegexHelper.h"
#import "YKServiceTool.h"
#import "YKClientSocket.h"
#import "YKServiceShell.h"
#import "YKServiceModel.h"
#import "YKServiceLogger.h"
#import "YKServiceEncrypt.h"
#import "YKPictureManager.h"
#import "YKRecorderRunner.h"
#import "YKClientHeartBeat.h"
#import "YKPortScanManager.h"
#import "YKClientSocketWIFI.h"
#import "YKServiceIOSurface.h"
#import "YKServiceFileLogger.h"
#import "YKScreenLockedStatus.h"
#import "YKServiceFileManager.h"
#import "YKApplicationManager.h"
#import "YKFileTransferManager.h"
#import "YKServiceIPCController.h"
#import "YKListeningRingerState.h"
#import "YKServiceRemoteController.h"

#import "YKAppNetworkFix.h"

#define yk_refreshServiceListeningState                                 A13dfe4c32312593c25d7623f32ccb7c587
#define yk_configEventMap                                               B695b6fea23077f00103081872d1a7f7468
#define handleEvent_deviceInfo                                          C195ac48123e65d2391a6d0acfcf0257850
#define yksr_device                                                     D7537a211e3e68f827e53d7f4585fd3fce5
#define handleEvent_server                                              E9d2ff2d63c2857155bd4d785daf8674789
#define handleEvent_videoSettings                                       F199ae223aa1cf1cf2f9f1146495e700873
#define handleEvent_mouse                                               Gnxr12339b5fab2daad444dxfwsc494ab8f
#define handleEvent_changeScreenLockedStatus                            H6b5e923e8b43189316c12e10ff3e660239
#define handleEvent_reboot                                              I81613ef4023a1d4fc1d1032cdcc4b5de77
#define handleEvent_fileList                                            Je29823f309d47b6ce85e6b3a5422de0338
#define handleEvent_transferFile                                        K388edaec78523ea60f52258502d0b03dd4
#define handleEvent_renameItem                                          L7ab422623e28ac33672dc36e7436d85511
#define handleEvent_createDirectory                                     Mdd230d1238cbc4d4263ac4b42bbf1d59ef
#define handleEvent_removeItem                                          Nca0e4238c5ec2545e519be1957ad83836d
#define handleEvent_extractArchive                                      O5edc54223bbe86a406064ed44eff846bd4
#define handleEvent_compressArchive                                     Pba49742319146b389aae354f6840dc286a
#define handleEvent_keyboard                                            Q658f0238816d348cf8702d1ce387cc7515
#define handleEvent_deviceName                                          R7d582523f568b825018d827aa5b9424685
#define handleEvent_volumeControl                                       S6b384321232f213e33c619221951f19b0c
#define handleEvent_homeScreen                                          Tf3e28d2361fa980f78f65e67ca16fa75fa
#define handleEvent_killAllApp                                          U81b3a8f023186ea32cb74c888a6706787b
#define handleEvent_recorder                                            Vcf0992395d9e35d63552080928247baca4
#define handleEvent_playback                                            W59eff7239c9c6f61fe94c4170d93ea92f2
#define handleEvent_showCenterController                                X339da20ea93d9d6bea4426425e990d6236
#define handleEvent_deleteAllPhotos                                     Yea42d23c762deccf87d0bbf392e1efe2e4
#define handleEvent_clipboard                                           Z01a42310f5abd29c2dd4fbcb67bf4658b7
#define handleEvent_getClipboard                                        Ab0e62xd259e45e0d244ad2d49c3d4cb5be
#define handleEvent_screenshot                                          A1982dd79cbb2v593ca8df62c86bca7abf2
#define handleEvent_appSwitcher                                         Bf99a6b3d87cc56471831629ae113c152ce
#define handleEvent_setWifiEnable                                       C22a1cx7cfff965043ffe2b9096d711270e
#define handleEvent_setCellularDataEnable                               D322bc04ac2d236caa56e1faf9386d085ce
#define handleEvent_appList                                             E2ac7fxf4dbb130f552c1fcea49638027da
#define handleEvent_appOperation                                        F3a487325e0d84596d773b7b650d1c0cc2x
#define handleEvent_videoPort                                           G9b7f72ea28dbcd2d49aef7e9592ab1b580
#define handleEvent_audioPort                                           Hbe9f78fcs1accf3fb2079dfa3989cf8d9d
#define yksr_performHTTPRequest                                         Id28055816f2d889ac9a764f24bcc35f06c
#define handleEvent_reject                                              J1bdf8cbedc60fe3193563ad58c12b61e21



@interface YKServiceRemoteController()
@property(nonatomic, readonly) YKPortScanManager *portScanManager;//端口扫描管理类
@property(nonatomic, readonly) YKClientSocket *clientSocket;//客户端Socket
@property(nonatomic, weak) YKServiceIPCController *serviceIPCController;//进程间的通讯
@property(nonatomic, readonly) YKScreenLockedStatus *screenLockedStatus;//屏幕锁屏状态监听
@property(nonatomic, readonly) YKFileTransferManager *fileTransferManager;//文件传输管理类
@property(nonatomic, readonly) YKRecorder *recorder;//录制类
@property(nonatomic, readonly) YKRecorderRunner *recorderRunner;//录制脚本执行类
@property(nonatomic, readonly) YKClientHeartBeat *clientHeartBeat;//心跳服务
@property(nonatomic, readonly) YKKBDManager *kbdManager;//键盘管理类
@property(nonatomic, readonly) YKListeningRingerState *listeningRingerState;//监听静音开关
@property(nonatomic, strong) YKServiceModel *serviceModel;//服务实体
@property(nonatomic, strong) NSDictionary *information;//信息
@property(nonatomic, strong) NSDictionary *eventStrategyMap;//事件映射(这样子写容易混淆)
@property(nonatomic, copy) NSString *deviceName;//设备名称
@end

@interface YKServiceRemoteController(PortScanManagerDelegate) <YKPortScanManagerDelegate>
@end

@interface YKServiceRemoteController(ClientSocketDelegate) <YKClientSocketDelegate>
@end

@interface YKServiceRemoteController(ServiceIPCControllerDelegate) <YKServiceIPCControllerDelegate>
@end

@interface YKServiceRemoteController(ScreenLockedStatusDelegate) <YKScreenLockedStatusDelegate>
@end

@interface YKServiceRemoteController(ListeningRingerStateDelegate) <YKListeningRingerStateDelegate>
@end

@interface YKServiceRemoteController(RecorderRunnerDelegate) <YKRecorderRunnerDelegate>
@end

@interface YKServiceRemoteController(ClientHeartBeatDelegate) <YKClientHeartBeatDelegate>
@end

@implementation YKServiceRemoteController


-(instancetype)initWithIPCController:(YKServiceIPCController *)iPCController
{
    self = [super init];
    if (self)
    {
        
        _deviceName = UIDevice.currentDevice.name;
        _orientation = 1;//默认竖屏
        [self yk_configEventMap];
        _serviceModel = [YKServiceModel loadFromDisk];
        
        _portScanManager = [[YKPortScanManager alloc] initWithPort:YK_WIFI_LISTEN_PORT delegate:self];
        _clientSocket = [[YKClientSocket alloc] initWithDelegate:self];
        
        _serviceIPCController = iPCController;
        _serviceIPCController.delegate = self;
        
        _screenLockedStatus = [[YKScreenLockedStatus alloc] init];
        _screenLockedStatus.delegate = self;
        
        _fileTransferManager = [[YKFileTransferManager alloc] init];
        
        _recorder = [[YKRecorder alloc] init];
        
        _recorderRunner = [[YKRecorderRunner alloc] init];
        _recorderRunner.delegate = self;
        
        _kbdManager = [[YKKBDManager alloc] init];
        
        _listeningRingerState = [[YKListeningRingerState alloc] init];
        _listeningRingerState.delegate = self;
        
        _clientHeartBeat = [[YKClientHeartBeat alloc] initWithDelegate:self];
        
        [self yk_refreshServiceListeningState];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            LOGI(@"执行了测试");
        });
    }
    return self;
}


#pragma mark - 配置事件映射
-(void)yk_configEventMap {
    
    self.eventStrategyMap = @{
        @"deviceInfo": NSStringFromSelector(@selector(handleEvent_deviceInfo:yksr_device:)),
        @"server": NSStringFromSelector(@selector(handleEvent_server:yksr_device:)),
        @"videoSettings": NSStringFromSelector(@selector(handleEvent_videoSettings:yksr_device:)),
        @"mouse": NSStringFromSelector(@selector(handleEvent_mouse:yksr_device:)),
        @"changeScreenLockedStatus": NSStringFromSelector(@selector(handleEvent_changeScreenLockedStatus:yksr_device:)),
        @"reboot": NSStringFromSelector(@selector(handleEvent_reboot:yksr_device:)),
        @"fileList": NSStringFromSelector(@selector(handleEvent_fileList:yksr_device:)),
        @"transferFile": NSStringFromSelector(@selector(handleEvent_transferFile:yksr_device:)),
        @"renameItem": NSStringFromSelector(@selector(handleEvent_renameItem:yksr_device:)),
        @"createDirectory": NSStringFromSelector(@selector(handleEvent_createDirectory:yksr_device:)),
        @"removeItem": NSStringFromSelector(@selector(handleEvent_removeItem:yksr_device:)),
        @"extractArchive": NSStringFromSelector(@selector(handleEvent_extractArchive:yksr_device:)),
        @"compressArchive": NSStringFromSelector(@selector(handleEvent_compressArchive:yksr_device:)),
        @"keyboard": NSStringFromSelector(@selector(handleEvent_keyboard:yksr_device:)),
        @"deviceName": NSStringFromSelector(@selector(handleEvent_deviceName:yksr_device:)),
        @"volumeControl": NSStringFromSelector(@selector(handleEvent_volumeControl:yksr_device:)),
        @"homeScreen": NSStringFromSelector(@selector(handleEvent_homeScreen:yksr_device:)),
        @"killAllApp": NSStringFromSelector(@selector(handleEvent_killAllApp:yksr_device:)),
        @"recorder": NSStringFromSelector(@selector(handleEvent_recorder:yksr_device:)),
        @"playback": NSStringFromSelector(@selector(handleEvent_playback:yksr_device:)),
        @"showCenterController": NSStringFromSelector(@selector(handleEvent_showCenterController:yksr_device:)),
        @"deleteAllPhotos": NSStringFromSelector(@selector(handleEvent_deleteAllPhotos:yksr_device:)),
        @"clipboard": NSStringFromSelector(@selector(handleEvent_clipboard:yksr_device:)),
        @"getClipboard":NSStringFromSelector(@selector(handleEvent_getClipboard:yksr_device:)),
        @"screenshot": NSStringFromSelector(@selector(handleEvent_screenshot:yksr_device:)),
        @"appSwitcher": NSStringFromSelector(@selector(handleEvent_appSwitcher:yksr_device:)),
        @"setWifiEnable": NSStringFromSelector(@selector(handleEvent_setWifiEnable:yksr_device:)),
        @"setCellularDataEnable": NSStringFromSelector(@selector(handleEvent_setCellularDataEnable:yksr_device:)),
        @"appList": NSStringFromSelector(@selector(handleEvent_appList:yksr_device:)),
        @"appOperation": NSStringFromSelector(@selector(handleEvent_appOperation:yksr_device:)),
        @"videoPort": NSStringFromSelector(@selector(handleEvent_videoPort:yksr_device:)),
        @"audioPort": NSStringFromSelector(@selector(handleEvent_audioPort:yksr_device:)),
        @"reject": NSStringFromSelector(@selector(handleEvent_reject:yksr_device:)),
    };
    
}

#pragma mark - 刷新服务状态
-(void)yk_refreshServiceListeningState {
    
    if (_serviceModel.isServiceEnabled) {
        
        NSError *error;
        [_portScanManager startWithError:&error];
        [_clientSocket ykcs_start];
        
    } else {
        [_portScanManager stop];
        [_clientSocket ykcs_stop];
    }
}

#pragma mark - 更新屏幕方向
-(void)setOrientation:(UIInterfaceOrientation)orientation {
    _orientation = orientation;
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"orientation", @"data":@(orientation)}];
    [_clientSocket ykcs_sendData:data];
}


#pragma mark - USB发送注册信息
-(void)handleEvent_deviceInfo:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *result = json[@"data"];
    NSString *remoteDeviceName = result[@"remoteDeviceName"];
    if (remoteDeviceName.length <= 0) {
        remoteDeviceName = @"USB-设备";//默认名称
    }
    device.remoteDeviceName = remoteDeviceName;//设置设备名称
    [self ykcs_clientSocket:_clientSocket ykcs_didAddDevice:device];//发送注册信息
}

#pragma mark - 处理时间验证
-(void)handleEvent_server:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    _information = json[@"data"];
    [_clientHeartBeat start];
}

#pragma mark - 设置视频配置
-(void)handleEvent_videoSettings:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *result = json[@"data"];
    [_delegate yksr_serviceRemoteController:self yksr_videoSettings:result];
}


#pragma mark - 设置Touch事件
-(void)handleEvent_mouse:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *data = json[@"data"];
    int type = [data[@"type"] intValue];
    int x = [data[@"x"] intValue];
    int y = [data[@"y"] intValue];
    
    int touchId = 1;
    if ([data.allKeys containsObject:@"touchId"]) {
        touchId = [data[@"touchId"] intValue];
    }
    
    //LOGI(@"滑动的时候会发多个事件%@", data);
    if(type==1)
    {
        [YKSimulator touchDown:CGPointMake(x, y) fingerId:touchId];
    }
    else if(type==2)
    {
        [YKSimulator touchUp:CGPointMake(x, y) fingerId:touchId];
    }
    else if(type==3)
    {
        [YKSimulator touchMove:CGPointMake(x, y) fingerId:touchId duration:0];
    }
}

#pragma mark - 改变屏幕锁屏状态
-(void)handleEvent_changeScreenLockedStatus:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    bool data = [json[@"data"] boolValue];
    if (data) {
        if ([self.screenLockedStatus fetchCurrentLockState]) {
            //因为PC端USB解锁的时候如果马上点击登陆，就有很大概率PC端的状态会一直是锁屏状态，但是其实我锁屏状态已发送过去了
            NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"lockedStatus", @"data": @(YES)}];
            [self.clientSocket ykcs_sendData:data];
        }
        //这边设置这个屏幕锁，是因为如果hook系统的锁屏在iOS13开始，能锁住，但是屏幕不会暗
        [YKSimulator powerPress];
    } else {
        // 解锁
        if (![self.screenLockedStatus fetchCurrentLockState]) {
            //因为PC端USB解锁的时候如果马上点击登陆，就有很大概率PC端的状态会一直是锁屏状态，但是其实我解锁状态已发送过去了
            NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"lockedStatus", @"data": @(NO)}];
            [self.clientSocket ykcs_sendData:data];
        }
        [_serviceIPCController ykipc_screenUnlock];
    }
}

#pragma mark - 重启SpringBoard
-(void)handleEvent_reboot:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    [YKServiceShell simple:@"killall -9 SpringBoard"];
}


#pragma mark - 处理文件列表
-(void)handleEvent_fileList:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    if (data.length > 0) {
        NSArray *array = [YKServiceFileManager findFileListInfo:data];
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event": @"fileList", @"data":@{@"path": data, @"list":array}}];
        [_clientSocket ykcs_sendData:result ykcs_device:device];
    }
}

#pragma mark - 处理传输文件
-(void)handleEvent_transferFile:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *result = json[@"data"];
    if ([result.allKeys containsObject:@"path"])
    {
        //处理传输文件
        int type = [result[@"type"] intValue];
        if (type == 1)
        {
            //手机上传文件到PC
            YKFileUploadModel *model = [[YKFileUploadModel alloc] init];
            model.identity = result[@"id"];
            model.ip = device.ip;
            model.port = [result[@"port"] intValue];
            model.path = result[@"path"];
            __weak typeof(self) weakSelf = self;
            [_fileTransferManager addFileUploadModel:model portCallback:^(UInt16 port) {
                
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferPort", @"data":@{@"id": model.identity, @"port": @(port)}}];
                [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
                
            } completion:^(BOOL success, NSString * _Nonnull msg) {
                
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferStatus", @"data":@{@"id": model.identity, @"code": @(success == YES ? 0 : -1), @"msg": msg, @"result": [YKServiceFileManager getFileInfo:model.path]}}];
                [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
            }];
            
            
        } else if (type == 2) {
            
            //PC文件上传到手机
            YKFileDownloadModel *model = [[YKFileDownloadModel alloc] init];
            model.identity = result[@"id"];
            model.ip = device.ip;
            model.port = [result[@"port"] intValue];
            model.path = result[@"path"];
            model.totalFileSize = [result[@"size"] longLongValue];
            
            __weak typeof(self) weakSelf = self;
            [_fileTransferManager addFileDownloadModel:model portCallback:^(UInt16 port) {
                
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferPort", @"data":@{@"id": model.identity, @"port": @(port)}}];
                [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
                
            } completion:^(BOOL success, NSString * _Nonnull msg) {
                
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferStatus", @"data":@{@"id": model.identity, @"code": @(success == YES ? 0 : -1), @"msg": msg, @"result": [YKServiceFileManager getFileInfo:model.path]}}];
                [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
            }];
        }
    } else if ([result.allKeys containsObject:@"name"]) {
        
        // 处理窗口
        
        YKFileDownloadModel *model = [[YKFileDownloadModel alloc] init];
        model.identity = result[@"id"];
        model.ip = device.ip;
        model.port = [result[@"port"] intValue];
        
        NSString *name = result[@"name"];
        NSString *ext = [name pathExtension];
        NSString *randomName = [[NSUUID UUID] UUIDString];
        //这边为什么要随机值，因为这边的文件是有写入操作的，然后如果同名的情况下，一个在写入一个又在更改，就会出问题
        model.path = [NSString stringWithFormat:@"%@%@.%@", YK_DOWNLOADS_PATH, randomName, ext];
        model.totalFileSize = [result[@"size"] longLongValue];
        
        
        __weak typeof(self) weakSelf = self;
        [_fileTransferManager addFileDownloadModel:model portCallback:^(UInt16 port) {
            
            NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferPort", @"data":@{@"id": model.identity, @"port": @(port)}}];
            [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
            
        } completion:^(BOOL success, NSString * _Nonnull msg) {
            
            NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"transferStatus", @"data":@{@"id": model.identity, @"code": @(success == YES ? 0 : -1), @"msg": msg}}];
            [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
            
            if (success)
            {
                // 获取文件的扩展名，忽略大小写
                NSString *extension = [[model.path pathExtension] lowercaseString];
                if ([extension isEqualToString:@"deb"]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [weakSelf.serviceIPCController ykipc_installDeb:model.path completion:^(BOOL result, NSString * _Nonnull message) {
                            NSData *installData = [YKServiceTool dataFromDictionary:@{@"event": @"debInstallStatus", @"data":@{@"id": model.identity, @"code": @(result == YES ? 0 : -1), @"msg": message}}];
                            [weakSelf.clientSocket ykcs_sendData:installData ykcs_device:device];
                            [[NSFileManager defaultManager] removeItemAtPath:model.path error:nil];
                        }];
                    });
                } else if ([extension isEqualToString:@"ipa"]) {
                    // 处理 .ipa 文件
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [YKApplicationManager installApp:model.path completion:^(BOOL result, NSString *message) {
                            
                            NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"ipaInstallStatus", @"data":@{@"code": @(result == true ? 0 : -1), @"msg": message}}];
                            [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
                            [[NSFileManager defaultManager] removeItemAtPath:model.path error:nil];
                        }];
                    });
                    
                    
                } else if ([@[@"jpg", @"jpeg", @"png", @"bmp", @"gif", @"mp4", @"mov", @"avi", @"mkv", @"flv", @"wmv", @"webp"] containsObject:extension])
                {
                    [YKPictureManager decompressionProcess:model.path completion:^(BOOL result, NSString * _Nonnull message) {
                        
                        NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"pictureStatus", @"data":@{@"code": @(result == true ? 0 : -1), @"msg": message}}];
                        [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
                        [NSFileManager.defaultManager removeItemAtPath:model.path error:nil];
                    }];
                }
            }
        }];
        
    }
}


#pragma mark - 文件重命名
-(void)handleEvent_renameItem:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device
{
    NSDictionary *data = json[@"data"];
    NSString *atPath = data[@"atPath"];
    NSString *toPath = data[@"toPath"];
    
    __weak typeof(self) weakSelf = self;
    [YKServiceFileManager renameItemAtPath:atPath toName:toPath completion:^(BOOL success, NSString * error) {
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"renameItemStatus", @"data": @{@"code": @(success == YES ? 0 : -1), @"msg": error, @"atPath": atPath, @"toPath":toPath}}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}

#pragma mark - 创建文件夹
-(void)handleEvent_createDirectory:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    __weak typeof(self) weakSelf = self;
    [YKServiceFileManager createDirectoryAtPath:data completion:^(BOOL success, NSString * error) {
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"createDirectoryStatus", @"data": @{@"code": @(success == YES ? 0 : -1), @"msg": error, @"path": data}}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}

#pragma mark - 删除文件项
-(void)handleEvent_removeItem:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    __weak typeof(self) weakSelf = self;
    [YKServiceFileManager deleteItemAtPath:data completion:^(BOOL success, NSString * error) {
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"removeItemStatus", @"data": @{@"code": @(success == YES ? 0 : -1), @"msg": error, @"path": data}}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}

#pragma mark - 解压
-(void)handleEvent_extractArchive:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    __weak typeof(self) weakSelf = self;
    [YKArchive.sharedInstance extractArchiveAtPath:data completion:^(BOOL success, NSString * _Nonnull msg, NSString * _Nonnull filePath) {
        
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"extractArchiveStatus", @"data": @{@"code": @(success == YES ? 0 : -1), @"msg": msg, @"result": [YKServiceFileManager getFileInfo:filePath]}}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}

#pragma mark - 压缩Zip
-(void)handleEvent_compressArchive:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    __weak typeof(self) weakSelf = self;
    [YKArchive.sharedInstance compressArchiveAtPath:data completion:^(BOOL success, NSString * _Nonnull msg, NSString * _Nonnull zipPath) {
        
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"compressArchiveStatus", @"data": @{@"code": @(success == YES ? 0 : -1), @"msg": msg, @"result": [YKServiceFileManager getFileInfo:zipPath]}}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}


#pragma mark - 处理键盘
-(void)handleEvent_keyboard:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device
{
    NSDictionary *data = json[@"data"];
    NSString *key = data[@"key"];
    NSString *chineseText = YKKeyMap.chineseKeyMap[key];
    if (chineseText && _kbdManager.isChineseInput) {
        
        static BOOL isDoubleQuote = false;
        if ([chineseText isEqualToString:@"“"])
        {
            if (isDoubleQuote) {
                chineseText = @"”";// 如果是双引号，切换为右双引号
                isDoubleQuote = NO;
            } else {
                isDoubleQuote = YES;
            }
        }
        
        //普通文本
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        pb.string = chineseText;
        
        // 模拟Ctr+V
        [YKSimulator pastePress];
    } else {
        NSArray *keyCodes = YKKeyMap.keyboardKeyMap[key];
        switch (keyCodes.count) {
            case 1:
            {
                // 如果只有一个按键代码，直接按下字符键
                [YKSimulator keyPressCode:[keyCodes[0] intValue] action:0]; // 按下字符键
            }
                break;
            case 2: {
                
                // 如果有两个按键代码，按住 Shift 键并按下字符键
                [YKSimulator keyPressCode:[keyCodes[0] intValue] action:1]; // 修饰键
                [YKSimulator keyPressCode:[keyCodes[1] intValue] action:0]; // 键
                [YKSimulator keyPressCode:[keyCodes[0] intValue] action:2]; // 修饰键
                usleep(50 * 1000); // 延迟 50 毫秒
            }
                break;
            case 3: {
                
                [YKSimulator keyPressCode:[keyCodes[0] intValue] action:1]; // 修饰键
                [YKSimulator keyPressCode:[keyCodes[1] intValue] action:1]; // 修饰键
                [YKSimulator keyPressCode:[keyCodes[2] intValue] action:0]; // 键
                [YKSimulator keyPressCode:[keyCodes[0] intValue] action:2]; // 修饰键
                [YKSimulator keyPressCode:[keyCodes[1] intValue] action:2]; // 修饰键
                usleep(50 * 1000); // 延迟 50 毫秒
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - 设置设备名称
-(void)handleEvent_deviceName:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *newName = json[@"data"];
    _deviceName = newName;
    [_serviceIPCController ykipc_setDeviceName:newName];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_serviceIPCController ykipc_updateConnect];
    });;
}

#pragma mark - 设置音量控制
-(void)handleEvent_volumeControl:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    if ([data isEqualToString:@"+"]) {
        
        [YKSimulator volupPress];
    } else if ([data isEqualToString:@"-"]) {
        
        [YKSimulator voldownPress];
    } else if ([data isEqualToString:@"ON"])
    {
        [YKSimulator mutePress];
    } else if ([data isEqualToString:@"OFF"]) {
        [YKSimulator mutePress];
    }
}

#pragma mark - 打开首页
-(void)handleEvent_homeScreen:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    [_serviceIPCController ykipc_homeScreen];
}


#pragma mark - 关闭所有App
-(void)handleEvent_killAllApp:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    [_serviceIPCController ykipc_killAllApp];
}


#pragma mark - 录制
-(void)handleEvent_recorder:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *data = json[@"data"];
    if ([data isEqualToString:@"start"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.recorder.isRuning)
            {
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"recorderStatus", @"data":@{@"code": @(-1), @"msg": [NSString stringWithFormat:@"录制功能已被【%@】占用", self.recorder.deviceName]}}];
                [self.clientSocket ykcs_sendData:data ykcs_device:device];
            } else {
                
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"recorderStatus", @"data":@{@"code": @(0), @"msg": @"成功"}}];
                [self.clientSocket ykcs_sendData:data ykcs_device:device];
                self.recorder.identifier = device.identifier;
                self.recorder.deviceName = device.remoteDeviceName;
                [self.recorder prepare];
                __weak typeof(self) weakSelf = self;
                [self.serviceIPCController ykipc_startRecordAnimation:^{
                    
                    LOGI(@"开始录制了");
                    [weakSelf.recorder start];
                }];
            }
        });
        
    } else if ([data isEqualToString:@"stop"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak typeof(self) weakSelf = self;
            [self.serviceIPCController ykipc_stopRecordAnimation];
            [self.recorder stop:^(NSString * _Nonnull content) {
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"recorderReport", @"data":content}];
                LOGI(@"录制的数据%@",content);
                [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
            }];
        });
    }
}


#pragma mark - 回放录制过程
-(void)handleEvent_playback:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *data = json[@"data"];
    NSString *type = data[@"type"];
    if ([type isEqualToString:@"start"]) {
        
        NSString *script = data[@"script"];
        int repeat = [data[@"repeat"] intValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.recorderRunner.state == YKRecorderRunnerStateRunning)
            {
                NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(-1), @"msg": [NSString stringWithFormat:@"回放功能已被【%@】占用", self.recorderRunner.receiptObject.remoteDeviceName]}}];
                [self.clientSocket ykcs_sendData:data ykcs_device:device];
            } else {
                
                self.recorderRunner.receiptObject = device;
                [self.recorderRunner loadScript:script repeat:repeat];
            }
        });
    } else if ([type isEqualToString:@"stop"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recorderRunner stop];
        });
    } else if ([type isEqualToString:@"pause"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recorderRunner pause];
        });
    } else if ([type isEqualToString:@"resume"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recorderRunner resume];
        });
    }
}

#pragma mark - 显示控制中心
-(void)handleEvent_showCenterController:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    [self.serviceIPCController ykipc_showCenterController];
}


#pragma mark - 处理相册
-(void)handleEvent_deleteAllPhotos:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    __weak typeof(self) weakSelf = self;
    [YKPictureManager deleteAllPhotos:^(BOOL success, NSError * _Nullable error) {
        
        NSString *msg = @"";
        if (success) {
            msg = @"成功";
        } else {
            msg = error.localizedDescription;
        }
        NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"deleteAllPhotoStatus", @"data":@{@"code": @(success == true ? 0 : -1), @"msg": msg}}];
        [weakSelf.clientSocket ykcs_sendData:data ykcs_device:device];
    }];
}

#pragma mark - 剪切板
-(void)handleEvent_clipboard:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *data = json[@"data"];
    NSString *content = data[@"content"];
    int type = [data[@"type"] intValue];
    if (type == 2) {
        //图片
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:content options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [UIImage imageWithData:decodedData];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        pb.image = image;
    } else {
        
        //普通文本
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        NSCharacterSet *nonDigitSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        BOOL isNumeric = ([content rangeOfCharacterFromSet:nonDigitSet].location == NSNotFound);
        
        // 主要针对一些App的验证码的输入
        if (isNumeric && content.length > 0 && content.length <= 6) {
            // 模拟输入键盘
            for (NSUInteger i = 0; i < content.length; i++) {
                NSString *key = [content substringWithRange:NSMakeRange(i, 1)];
                NSArray *keyCodes = YKKeyMap.keyboardKeyMap[key];
                if (keyCodes && keyCodes.count > 0) {
                    [YKSimulator keyPressCode:[keyCodes[0] intValue] action:0]; // 按下
                    usleep(50 * 1000); // 延迟 50ms
                }
            }
            return;
        } else {
            // 普通文本直接写入剪切板
            pb.string = content;
        }
    }
    usleep(100 * 1000); // 延迟 100 毫秒
    [YKSimulator pastePress];
}

#pragma mark - 获取剪切板信息
-(void)handleEvent_getClipboard:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *temResul = [_serviceIPCController ykipc_getClipboardContentWaiting:NO];
    NSString *clipText = temResul[@"text"];
    int type = [temResul[@"type"] intValue];
    
    NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"clipboard", @"data": @{@"type": @(type), @"content": clipText, @"appName": @"getClipboard", @"bid": @""}}];
    [_clientSocket ykcs_sendData:result ykcs_device:device];
}


#pragma mark - 处理截图
-(void)handleEvent_screenshot:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSString *imgBase64 = YKScreenShotBase64(self.orientation);
    NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"clipboard", @"data": @{@"type": @(2), @"content": imgBase64, @"appName": @"远控Pro"}}];
    [_clientSocket ykcs_sendData:result ykcs_device:device];
}

#pragma mark - 处理后台切换
-(void)handleEvent_appSwitcher:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    [YKSimulator menuDoublePress];
}


#pragma mark - 处理WIFI开关
-(void)handleEvent_setWifiEnable:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    BOOL result = [json[@"data"] boolValue];
    [_serviceIPCController ykipc_setWifiEnable:result];
}

#pragma mark - 处理蜂窝开关
-(void)handleEvent_setCellularDataEnable:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    BOOL result = [json[@"data"] boolValue];
    [_serviceIPCController ykipc_setCellularDataEnable:result];
}


#pragma mark - 应用列表
-(void)handleEvent_appList:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    __weak typeof(self) weakSelf = self;
    [YKApplicationManager getAppsList:^(NSMutableArray<NSDictionary *> * _Nonnull appListResult) {
        
        NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"appList", @"data": appListResult}];
        [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
    }];
}


#pragma mark - 处理App操作
-(void)handleEvent_appOperation:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    NSDictionary *data = json[@"data"];
    int type = [data[@"type"] intValue];
    NSString *name = data[@"name"];
    NSString *identifier = data[@"identifier"];
    switch (type) {
        case 1:
        {
            BOOL isDeb = [YKApplicationManager isDebPackage:identifier];
            if (isDeb) {
                [self.serviceIPCController yjipc_uninstallDeb:identifier completion:^(BOOL result, NSString * _Nonnull debMsg) {
                    
                }];
            } else {
                [YKApplicationManager uninstallApp:identifier];
            }
        }
            break;
        case 2:
        case 3:
        {
            NSString *path = [_serviceIPCController ykipc_getAppDataPathWithType:type - 1 ykipc_identifier:identifier];
            NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"appOperation", @"data":@{@"path": path, @"identifier": identifier, @"name": name}}];
            [_clientSocket ykcs_sendData:result ykcs_device:device];
        }
            break;
        case 4: {
            NSString *path = [_serviceIPCController ykipc_getAppDataPathWithType:type - 1 ykipc_identifier:identifier];
            if (!path) {
                path = @"";
            }
            NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"appOperation", @"data": @{@"path": path, @"identifier": identifier, @"name": name}}];
            [_clientSocket ykcs_sendData:result ykcs_device:device];
        }
            break;
        case 5: {
            [YKApplicationManager clearCache:identifier];
        }
            break;
        case  6: {
            [YKApplicationManager clearKeyChain:identifier];
        }
            break;
        case 7: {
            [YKApplicationManager launch:identifier];
        }
            break;
        case 8: {
            [_serviceIPCController ykipc_killWithBid:identifier];
        }
            break;
        default:
            break;
    }
}


#pragma mark - 处理视频端口
-(void)handleEvent_videoPort:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    int videoPort = [json[@"data"] intValue];
    [_delegate yksr_serviceRemoteController:self yksr_videoIP:device.ip yksr_port:videoPort];
}

#pragma mark - 音频端口
-(void)handleEvent_audioPort:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    
    int port = [json[@"data"] intValue];
    if (port == 0) {
        //告诉PC端 音频端口
        __weak typeof(self) weakSelf = self;
        [_serviceIPCController ykipc_getAudioPort:^(BOOL su, UInt16 port) {
            
            LOGI(@"获取到的音频端口是%d", port);
            NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"audioPort", @"data": @{@"port": @(port)}}];
            [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
        }];
        
    } else {
        
        __weak typeof(self) weakSelf = self;
        [_serviceIPCController ykipc_connectAudioWithIP:device.ip ykipc_port:port completion:^(BOOL su, NSString * _Nonnull msg) {
            
            NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"audioPortStatus", @"data":@{@"code": @(su == true ? 0 : -1), @"msg": msg}}];
            [weakSelf.clientSocket ykcs_sendData:result ykcs_device:device];
        }];
    }
}


#pragma mark - PC拒绝连接
-(void)handleEvent_reject:(NSDictionary *)json yksr_device:(id<YKClientDeviceProtocol>)device {
    NSString *msg = json[@"data"];
    [_serviceIPCController ykipc_scanQrcodeReceipt:msg];
}
@end




//============================================================
// 扫描回调(局域网扫描连接请求)
//============================================================
@implementation YKServiceRemoteController(PortScanManagerDelegate)
-(void)ykpsm_portScanManager:(YKPortScanManager *)scan ykpsm_ip:(NSString *)ip ykpsm_port:(uint16_t)port ykpsm_remoteDeviceName:(NSString *)remoteDeviceName
{
    LOGI(@"收到局域网扫描请求了");
    @synchronized(self)
    {
        NSError *error;
        YKConnectionContext *context = [[YKConnectionContext alloc] init];
        context.medium = YKConnectionMediumWiFi;
        context.wifiMode = YKWiFiConnectionModePassive;
        if (![_clientSocket ykcs_startWithServerIp:ip ykcs_serverPort:port ykcs_remoteDeviceName:remoteDeviceName ykcs_connectionContext:context ykcs_error:&error])
        {
            LOGI(@"Socket连接服务器失败%@", error);
            return;
        }
    }
}
@end


//============================================================
// Socket回调
//============================================================
@implementation YKServiceRemoteController(ClientSocketDelegate)

-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_didAddDevice:(id<YKClientDeviceProtocol>)device
{
    // 在串行队列中处理，保证注册任务是第一个执行的
        NSString *localIp = [YKServiceTool getIpAddresses];
        NSArray  *ipArray = [localIp componentsSeparatedByString:@";"];
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        result[@"deviceId"] = [self.serviceIPCController ykipc_uuid];
        result[@"orientation"] = @(self.orientation);
        result[@"lockedStatus"] = @([self.screenLockedStatus fetchCurrentLockState]);
        result[@"deviceName"] = UIDevice.currentDevice.name;
        result[@"localIp"] = ipArray[0];
        result[@"model"] = [YKServiceTool platform];
        result[@"systemVersion"] = [[UIDevice currentDevice] systemVersion];
        result[@"version"] = [YKApplicationManager getVersionForBundleIdentifier:YK_BID];
        result[@"jbType"] = @(YKServiceTool.jbType);
        result[@"screenWidth"] = @([UIScreen mainScreen].currentMode.size.width);
        result[@"screenHeight"] = @([UIScreen mainScreen].currentMode.size.height);
        result[@"playbackStatus"] = @(self.recorderRunner.state);//录制脚本运行状态
        result[@"videoPort"] = @([self.delegate yksr_videoPortForServiceRemoteController:self]);
        result[@"choicyMsg"] = self.serviceIPCController.ykipc_choicyMsg ;//是否被屏蔽了
        result[@"springBoardMsg"] = self.serviceIPCController.ykipc_springBoardMsg;//是否需要重启
        
        if ([device isKindOfClass:[YKClientSocketWIFI class]]) {
            YKClientSocketWIFI *wifi = device;
            if (wifi.context.wifiMode == YKWiFiConnectionModeActive) {
                if (wifi.context.networkScope == YKNetworkScopeLAN) {
                    result[@"scanType"] = @(1);
                } else {
                    result[@"scanType"] = @(2);
                }
            } else {
                result[@"scanType"] = @(0);
            }
        } else {
            result[@"scanType"] = @(0);
        }
        LOGI(@"收到了新的设备注册了");
        NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"deviceInfo", @"data":result}];
        [self.clientSocket ykcs_sendData:data ykcs_device:device];
        //只要有注册信息就是代表有新的设备连接然后发送给App让App更新界面
        [self.serviceIPCController ykipc_updateConnect];
}


-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_device:(id<YKClientDeviceProtocol>)device ykcs_received:(NSDictionary *)data
{
    NSString *event = data[@"event"];
    NSString *selectorString = self.eventStrategyMap[event];
    SEL selector = NSSelectorFromString(selectorString);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:data withObject:device];
#pragma clang diagnostic pop
    } else {
        LOGI(@"未识别到该函数方法");
    }
}

-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_closeDevice:(id<YKClientDeviceProtocol>)device {
    
    [_serviceIPCController ykipc_updateConnect];
    if ([_clientSocket ykcs_getConnectedServices].count <= 0) {
        [_clientHeartBeat stop];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        LOGI(@"断开了设备了");
        if (self.recorder.isRuning && [self.recorder.identifier isEqualToString:device.identifier])
        {
            [self.serviceIPCController ykipc_stopRecordAnimation];
            [self.recorder stop:^(NSString * _Nonnull content) {
                LOGI(@"如果异常断开的时候,就要判断当前录制脚本是否正在运行，如果是的话，判断设备是不是同一个，如果是的话，就停止");
            }];
        }
    });
}

-(void)ykcs_clientSocket:(YKClientSocket *)clientSocket ykcs_scanQrCodeError:(NSString *)msg
{
    [_serviceIPCController ykipc_scanQrcodeReceipt:msg];
}
@end


//============================================================
// 进程通讯通知
//============================================================
@implementation YKServiceRemoteController(ServiceIPCControllerDelegate)
-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_didCopyContent:(NSString *)content ykipc_type:(int)type ykipc_appName:(nonnull NSString *)appName ykipc_bid:(nonnull NSString *)bid
{
    NSData *result = [YKServiceTool dataFromDictionary:@{@"event":@"clipboard", @"data": @{@"type": @(type), @"content": content, @"appName": appName, @"bid": bid}}];
    [_clientSocket ykcs_sendData:result];
}

-(NSArray *)ykipc_serviceIPCControllerConnectedServices:(YKServiceIPCController *)serviceIPCController {
    
    return [_clientSocket ykcs_getConnectedServices];
}

-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_qrCode:(NSString *)qrCode
{
    @try {
        
        if (!self.serviceModel.isServiceEnabled) {
            [_serviceIPCController ykipc_scanQrcodeReceipt:@"启动服务-已关闭,请先开启服务"];
            return;
        }
        
        
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:qrCode options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:&error];
        
        NSString *remoteDeviceName = json[@"remoteDeviceName"];
        int networkScope = 1;//默认局域网扫描
        if ([json.allKeys containsObject:@"networkScope"]) {
            networkScope = [json[@"networkScope"] intValue];
        }
        
        if (remoteDeviceName.length <= 0) {
            remoteDeviceName = @"设备";//默认名称
        }
        NSString *ip = json[@"ip"];
        int port = [json[@"port"] intValue];
        if (!ip)
        {
            [_serviceIPCController ykipc_scanQrcodeReceipt:YK_SCAN_QRCODE_ERROR_MSG];
            return;
        }
        
        
        YKConnectionContext *context = [[YKConnectionContext alloc] init];
        context.medium = YKConnectionMediumWiFi;
        context.wifiMode = YKWiFiConnectionModeActive;
        context.networkScope = networkScope == 1 ? YKNetworkScopeLAN : YKNetworkScopeWAN;
        context.hasShownPrompt = NO;
        if (![_clientSocket ykcs_startWithServerIp:ip ykcs_serverPort:port ykcs_remoteDeviceName:remoteDeviceName ykcs_connectionContext:context ykcs_error:&error])
        {
            [_serviceIPCController ykipc_scanQrcodeReceipt:[NSString stringWithFormat:@"连接失败%@", error.localizedDescription]];
            return;
        }
        
    } @catch (NSException *exception) {
        [_serviceIPCController ykipc_scanQrcodeReceipt:YK_SCAN_QRCODE_ERROR_MSG];
    }
}

-(BOOL)ykipc_serviceIPCControllerServiceEnabled:(YKServiceIPCController *)serviceIPCController {
    return _serviceModel.isServiceEnabled;
}

-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_isServiceEnabled:(BOOL)isServiceEnabled {
    _serviceModel.isServiceEnabled = isServiceEnabled;
    [_serviceModel saveToDisk];
    [self yk_refreshServiceListeningState];
}


-(void)ykipc_serviceIPCController:(YKServiceIPCController *)serviceIPCController ykipc_deviceNameChanged:(NSString *)deviceName {
    
    if (![self.deviceName isEqualToString:deviceName]) {
        self.deviceName = deviceName;
        NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"deviceNameChanged", @"data":deviceName}];
        [_clientSocket ykcs_sendData:data];
        [_serviceIPCController ykipc_updateConnect];
    }
}
@end

//============================================================
// 屏幕状态回调
//============================================================
@implementation YKServiceRemoteController(ScreenLockedStatusDelegate)
-(void)screenLockedStatusChanged:(BOOL)status
{
    LOGI(@"屏幕锁屏状态发生变化了=%d",status);
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"lockedStatus", @"data": @(status)}];
    [self.clientSocket ykcs_sendData:data];
    
    __weak typeof(self) weakSelf = self;
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           __strong typeof(weakSelf) strongSelf = weakSelf;
           if (!strongSelf) return;
           
           LOGI(@"[延迟发送] 2秒确认状态为: %d", status);
           NSData *delayedData = [YKServiceTool dataFromDictionary:@{@"event": @"lockedStatus", @"data": @([weakSelf.screenLockedStatus fetchCurrentLockState])}];
           [strongSelf.clientSocket ykcs_sendData:delayedData];
       });
}
@end


//============================================================
// 静音状态回调
//============================================================
@implementation YKServiceRemoteController(ListeningRingerStateDelegate)
-(void)listeningRingerState:(YKListeningRingerState *)manager didUpdateMuteState:(BOOL)isMuted
{
    LOGI(@"静音状态变更为: %@", isMuted ? @"静音" : @"响铃");
}
@end



//============================================================
// 心跳回调
//============================================================
@implementation YKServiceRemoteController(ClientHeartBeatDelegate)
-(void)didReceiveHeartBeat:(YKClientHeartBeat *)sender {
    
    [self yksr_performHTTPRequest];
}

#pragma mark - HTTP Request (网络请求)
-(void)yksr_performHTTPRequest {
    
    NSString *serverIP = _information[@"ip"];
    NSString * serverPort = _information[@"port"];
    NSString *accountId = _information[@"accountId"];
    NSString *udid = [_serviceIPCController ykipc_uuid];
    NSString *apiPath = @"/deviceStatus";
    // ---------------------------------------
    
    // 1. 拼接 URL (IP + Port)
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@%@", serverIP, serverPort, apiPath];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. 创建 Request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 5.0;
    
    // 3. 设置 Header：告诉服务器我们要发 JSON
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Accept"];
    
    // 4. 构建 JSON 数据
    NSDictionary *params = @{
        @"udid": udid ?: @"",
        @"accountId": accountId ?: @""
    };
    
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonError];
    
    if (jsonError) {
        //伪装5秒在关闭
        sleep(5);
        exit(0);
        return;
    }
    
    NSData *data = [YKServiceEncrypt yk_aesEncrypt:jsonData];
    
    // 6. 设置 Body
    request.HTTPBody = data;
    
    
    // 7. 发起请求
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        
        // 1. 网络层错误检查
        if (error) {
            LOGI(@"请求网络异常: %@", error.localizedDescription);
            return;
        }
        
        // 2. 检查 HTTP 状态码
        NSInteger statusCode = 0;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = [(NSHTTPURLResponse *)response statusCode];
        }
        
        // 只有 200 才继续，否则视为错误
        if (statusCode != 200) {
            LOGI(@"服务器响应错误，状态码: %ld", (long)statusCode);
            return;
        }
        
        // ============ 处理 0 或 1 的逻辑 ============
        if (data) {
            
            
            NSData *jsonData = [YKServiceEncrypt yk_aesDecrypt:data];
            if (jsonData == nil) {
                LOGI(@"解密失败: 得到空数据");
                return;
            }
            
            // 1. 将解密后的二进制数据转为 JSON 字典
            NSError *jsonError;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:0
                                                                       error:&jsonError];
            
            // 2. 校验：解析是否有错，或者解析出来的结果不是字典
            if (jsonError || ![jsonDict isKindOfClass:[NSDictionary class]]) {
                LOGI(@"JSON 解析失败: %@", jsonError ? jsonError.localizedDescription : @"返回格式错误(非字典)");
                return;
            }
            
            // 3. 提取 expired 属性
            // jsonDict[@"expired"] 可能是 NSNumber 或 NSString
            // 调用 boolValue 可以自动兼容：1, "1", true -> YES | 0, "0", false -> NO
            BOOL isExpired = [jsonDict[@"expired"] boolValue];
            
            LOGI(@"解析成功: %@", jsonDict);
            
            // 4. 根据 bool 值处理业务
            if (isExpired) {
                LOGI(@"状态: 已过期 (YES)");
                NSData *sendData = [YKServiceTool dataFromDictionary:@{@"event": @"deviceExpired", @"data": @(YES)}];
                [self.clientSocket ykcs_sendData:sendData];
                
            } else {
                LOGI(@"状态: 未过期 (NO)");
            }
        } else {
            LOGI(@"服务器返回了空数据 (Empty Body)");
        }
    }];
    
    [task resume];
}
@end


//============================================================
// 录制脚本回调
//============================================================
@implementation YKServiceRemoteController(RecorderRunnerDelegate)
-(void)recorderRunnerDidLoadScript:(YKRecorderRunner *)runner {
    
    LOGI(@"当脚本加载完成时回调");
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(1),  @"msg": @"脚本加载完成"}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
    [self.recorderRunner start];
}

-(void)recorderRunnerDidStart:(YKRecorderRunner *)runner {
    
    //LOGI(@"当脚本开始执行时回调");
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(2),  @"msg": @"脚本开始执行"}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
}

-(void)recorderRunnerDidPause:(YKRecorderRunner *)runner {
    
    //LOGI(@"当脚本暂停时回调");
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(3),  @"msg": @"脚本暂停"}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
}

-(void)recorderRunnerDidResume:(YKRecorderRunner *)runner {
    
    //LOGI(@"当脚本从暂停恢复执行时回调");
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(4),  @"msg": @"脚本从暂停恢复执行"}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
}

-(void)recorderRunnerDidFinish:(YKRecorderRunner *)runner
{
    //LOGI(@"当脚本执行完成（正常结束）时回调");
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(5),  @"msg": @"执行完成"}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
}

-(void)recorderRunnerDidRunToLine:(YKRecorderRunner *)runner totalLine:(NSInteger)totalLine currentLine:(NSInteger)line
{
    //LOGI(@"当前运行到了那一行%ld",(long)line);
    NSString *result = [NSString stringWithFormat:@"当前执行位置(%ld/%ld)行", line, totalLine];
    NSData *data = [YKServiceTool dataFromDictionary:@{@"event": @"playbackStatus", @"data":@{@"code": @(6), @"line": @(line), @"msg": result}}];
    [_clientSocket ykcs_sendData:data ykcs_device:runner.receiptObject];
}

-(void)recorderRunner:(YKRecorderRunner *)runner didFailWithError:(NSError *)error {
    
    LOGI(@"当脚本执行出错时回调 = %@", error.localizedDescription);
}
@end

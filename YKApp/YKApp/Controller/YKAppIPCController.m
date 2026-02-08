//
//  YKAppIPCController.m
//  YKApp
//
//  Created by liuxiaobin on 2025/10/11.
//

#import <YKXPC/YKXPC.h>
#import "YKAppLogger.h"
#import "YKAppIPCController.h"
#import <YKIPCKey/YKIPCKey.h>

#define yk_addNotication              Abf2c684bbb771a19e4a3eb6406d33e1ddf

@interface YKAppIPCController()
@property (nonatomic, strong) NSTimer *deviceInfoTimer;
@end

@implementation YKAppIPCController

#pragma mark - 初始化
-(instancetype)init {
    self = [super init];
    if (self) {
        [self yk_addNotication];
    }
    return self;
}

#pragma mark - 添加通知
-(void)yk_addNotication {
    
    __weak typeof(self) weakSelf = self;
    [YKNotificationRequest.shared addNotificationWithObserver:self port:NOTIFY_PORT_YK_APP completion:^(NSInteger cmd, NSString * _Nonnull replyID, NSDictionary * _Nonnull data)
     {
        LOGI(@"收到了数据%@", data);
        switch (cmd) {
            case YKSBNotificationTypeAppDeviceInfo:
            {
                [weakSelf.deviceInfoTimer invalidate];
                weakSelf.deviceInfoTimer = nil;
                NSDictionary *newData = [data copy];
                [weakSelf.delegate appIPCController:weakSelf deviceInfo:newData];
            }
                break;
            case YKSBNotificationTypeScanQrcode: {
                
                NSString *msg = data[@"msg"];
                [weakSelf.delegate appIPCController:weakSelf qrcodeMsg:msg];
            }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - 请求设备超时
-(void)yk_handleDeviceInfoTimeout {
    LOGI(@"请求设备信息超时了！");
    [self.deviceInfoTimer invalidate];
    self.deviceInfoTimer = nil;
    [self yk_readFirstCrashLog];
}

#pragma mark - 读取数据
-(void)yk_readFirstCrashLog {
    
    NSString *directoryPath = @"/var/mobile/Library/YKApp/CrashLogs/";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 1. 检查目录是否存在
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDir] || !isDir) {
        LOGI(@"错误：目录不存在 %@", directoryPath);
        return;
    }
    
    NSError *error = nil;
    // 2. 获取目录下所有文件
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        LOGI(@"读取目录失败: %@", error.localizedDescription);
        return;
    }
    
    // 3. 筛选出第一个 .txt 文件
    NSString *firstTxtFileName = nil;
    for (NSString *fileName in fileList) {
        if ([fileName.pathExtension.lowercaseString isEqualToString:@"txt"]) {
            firstTxtFileName = fileName;
            break; // 找到第一个就跳出循环
        }
    }
    
    if (firstTxtFileName) {
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:firstTxtFileName];
        
        // 4. 读取文件内容
        NSError *readError = nil;
        NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&readError];
        
        if (!readError) {
            LOGI(@"成功读取文件 [%@], 内容: %@", firstTxtFileName, content);
            
            // 在这里处理读取到的文本数据
            // 例如：解析内容并更新 UI，或者模拟一个成功的回调
            [self.delegate appIPCController:self firstTxtFileName:firstTxtFileName errorMsg:content];
        } else {
            LOGI(@"读取文件内容失败: %@", readError.localizedDescription);
        }
    } else {
        [self yk_getDeviceInfo];
    }
}



#pragma mark - 获取App信息
-(void)yk_getDeviceInfo {
    
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE cmd:YKSBNotificationTypeAppDeviceInfo];
    [self.deviceInfoTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.deviceInfoTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf yk_handleDeviceInfoTimeout];
    }];
}


#pragma mark - 回到首页
-(void)yk_homeScreen {
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE cmd:YKSBNotificationTypeHomeScreen];
}

#pragma mark - 一键重置
-(void)yk_reStart {
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_LAUNCHD cmd:YKSBNotificationTypeReStart];
}

#pragma mark - 打开设置
-(void)yk_openSetting {
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE cmd:YKSBNotificationTypePreferences];
}

#pragma mark - 扫描二维码
-(void)yk_scanQrcode:(NSString *)qrcode {
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE cmd:YKSBNotificationTypeScanQrcode data:@{@"qrcode": qrcode}];
}

#pragma mark - 设置服务是否启用
-(void)yk_isServiceEnabled:(BOOL)isServiceEnabled {
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE cmd:YKSBNotificationTypeServiceEnabled data:@{@"isServiceEnabled": @(isServiceEnabled)}];
}
@end

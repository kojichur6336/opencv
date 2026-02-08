//
//  YKService.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKService.h"
#import "YKCrashLogs.h"
#import "YKLockProcess.h"
#import "YKServiceLogger.h"
#import "YKOrientationObserver.h"
#import "YKServiceIPCController.h"
#import "YKServiceVideoController.h"
#import "YKServiceRemoteController.h"

 
#define ykser_sharedInstance                  Abf5fc7141c71e66932786980b4d9e52e82
#define ykser_runLoopRun                      B813f26512e45b77195ff5bc306fa0d2dde
#define ykser_ensureDirectories               C30f582s816eea3c43cdb6391dba801e6da
#define yk_serviceIPCController               Dc44944131sfd9b08de597dd1574ecc270d
#define yk_orientationObserver                E4584067ff2sf3226eb3dc85a5daa897b3b
#define yk_serviceRemoteController            F6b95c2s81d52cf7de4efa07160515f5d8c
#define yk_serviceVideoController             G9a52c914062s9b7c34455fe6ef7934e5d9


@interface YKService()<YKServiceRemoteControllerDelegate, YKOrientationObserverDelegate>
+(instancetype)ykser_sharedInstance;
-(void)ykser_runLoopRun;
@property(nonatomic, strong) YKServiceIPCController *yk_serviceIPCController;//进程通讯控制器
@property(nonatomic, strong) YKOrientationObserver *yk_orientationObserver;//屏幕方向监听
@property(nonatomic, strong) YKServiceRemoteController *yk_serviceRemoteController;//远程控制器
@property(nonatomic, strong) YKServiceVideoController *yk_serviceVideoController;//视频控制器
@end


@implementation YKService

+(instancetype)ykser_sharedInstance {
    static YKService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 运行
-(void)ykser_runLoopRun {
    
    self.yk_serviceIPCController = [[YKServiceIPCController alloc] init];
    self.yk_orientationObserver = [[YKOrientationObserver alloc] initWithDelegate:self];
    
    self.yk_serviceVideoController = [[YKServiceVideoController alloc] initWithIPCController:self.yk_serviceIPCController];
    self.yk_serviceRemoteController = [[YKServiceRemoteController alloc] initWithIPCController:self.yk_serviceIPCController];
    self.yk_serviceRemoteController.delegate = self;
    CFRunLoopRun();
}

#pragma mark - 切换视频清晰度
-(void)yksr_serviceRemoteController:(YKServiceRemoteController *)vc yksr_videoSettings:(NSDictionary *)setting
{
    [self.yk_serviceVideoController yksv_updateVideoWithSetting:setting];
}

-(UInt16)yksr_videoPortForServiceRemoteController:(YKServiceRemoteController *)vc
{
    return self.yk_serviceVideoController.yksv_videoPort;
}

-(void)yksr_serviceRemoteController:(YKServiceRemoteController *)vc yksr_videoIP:(NSString *)ip yksr_port:(int)port
{
    [self.yk_serviceVideoController yksv_connectRemoteVideo:ip yksv_port:port];
}

#pragma mark - 方向发生变化的时候
-(void)didChangeOrientation:(UIInterfaceOrientation)orientation {
    self.yk_serviceVideoController.orientation = orientation;
    self.yk_serviceRemoteController.orientation = orientation;
}
@end


#pragma mark - 还原系统的时候确保能再次启动成功
void ykser_ensureDirectories(void)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *dirs = @[
        @"/var/mobile/Library/YKApp",
        @"/var/mobile/Library/YKApp/Config",
        @"/var/mobile/Library/YKApp/Logs",
        @"/var/mobile/Library/YKApp/CrashLogs",
        @"/var/mobile/Library/YKApp/Downloads",
        @"/var/mobile/Library/YKApp/Downloads/Tmp",
        @"/var/mobile/Library/YKApp/Downloads/Deb",
        @"/var/mobile/Library/YKApp/Downloads/Ipa"
    ];

    NSDictionary *attr = @{NSFilePosixPermissions: @0755};

    for (NSString *dir in dirs)
    {
        if (![fm fileExistsAtPath:dir])
        {
            NSError *error = nil;
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:attr error:&error];
            if (error) {
                LOGI(@"文件创建失败%@",error.localizedDescription);
            }
        }
    }
}


int main(int argc, char * argv[])
{
    YKCrashLogs::getInstance().regiSignal();
    ykser_ensureDirectories();
    [YKLockProcess lockProcess];
    @autoreleasepool {
        setsid();
        [[YKService ykser_sharedInstance] ykser_runLoopRun];
    }
    return 0;
}

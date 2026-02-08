//
//  YKLaunchdService.m
//  YKLaunchd
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKShell.h"
#import <sys/sysctl.h>
#import <YKXPC/YKXPC.h>
#import <UIKit/UIKit.h>
#import "YKLaunchdLogger.h"
#import "YKLaunchdService.h"
#import <YKIPCKey/YKIPCKey.h>

#define addNotifi                   A6a12rxee4002c938c89eb5313064f7dbf8
#define serviceRunWatchDog          B171195cc671e48d6d3d361d2f27911661e
#define serviceStart                Ce5f63x28b248df069025e3053f8b326a71


#define kYKSBService  @"YKService"

@interface YKLaunchdService()
@property(nonatomic, assign) CFRunLoopTimerRef watchDogTimer;//看门狗定义的定时器
@property(nonatomic, strong) dispatch_source_t timer;
@end

@implementation YKLaunchdService

-(instancetype)init {
    self = [super init];
    if (self) {
        [self addNotifi];
        [self serviceRunWatchDog];
    }
    return self;
}

#pragma mark - 看门狗启动
-(void)serviceRunWatchDog {
    
    [self serviceStart];
    __weak typeof(self) weakSelf = self;
    CFTimeInterval interval = 5.0f;
    CFAbsoluteTime fireDate = CFAbsoluteTimeGetCurrent() + interval;
    self.watchDogTimer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, interval, 0, 0, ^(CFRunLoopTimerRef timer) {
        [weakSelf serviceStart];
    });
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), weakSelf.watchDogTimer, kCFRunLoopCommonModes);
}


#pragma mark - 启动服务
-(void)serviceStart
{
    int pid;
    if (![self isProcessRunning:kYKSBService processID:&pid])
    {
        NSString *servicePath = [NSString stringWithFormat:@"%@%@",@"/Applications/YKApp.app/bin/",kYKSBService];
        NSString *cmd = [NSString stringWithFormat:@"nohup %@ > /dev/null 2>&1 &",[YKShell conversionJBRoot:servicePath]];
        [YKShell simple:cmd];
    }
}

#pragma mark - 添加通知
-(void)addNotifi {
    
    __weak typeof(self) weakSelf = self;
    [YKNotificationRequest.shared addNotificationWithObserver:self port:NOTIFY_PORT_YK_LAUNCHD completion:^(NSInteger cmd, NSString * _Nonnull replyID, NSDictionary * _Nonnull data) {
        
        switch (cmd) {
            case YKSBNotificationTypeInstallDEB:
            {
                NSString *path = [YKShell getRootFSPath:data[@"path"]];
                [YKShell simple:[NSString stringWithFormat:@"dpkg -i '%@'",path] completion:^(BOOL result, NSString * _Nullable msg) {
                    
                    NSString *temMsg;
                    if (result) {
                        temMsg = @"安装成功";
                    } else {
                        temMsg = msg;
                    }
                    [YKNotificationRequest.shared postWithPort:replyID data:@{@"status":@(result), @"msg": temMsg}];
                }];
            }
                break;
            case YKSBNotificationTypeUnInstallDEB: {
                NSString *packageName = data[@"bid"];
                [YKShell simple:[NSString stringWithFormat:@"nohup apt-get remove --purge -y %@ > /dev/null 2>&1 &",packageName] completion:^(BOOL result, NSString * _Nullable msg) {
                    [YKNotificationRequest.shared postWithPort:replyID data:@{@"status":@(result), @"msg": msg}];
                }];
            }
                break;
            case YKSBNotificationTypeReStart: {
                
                int pid;
                BOOL result = [weakSelf isProcessRunning:kYKSBService processID:&pid];
                if (result) {
                    kill(pid, SIGKILL);
                }
                [YKShell simple: @"killall -9 SpringBoard > /dev/null"];
            }
                break;
            case YKSBNotificationTypeAudioDylibInject: {
                //重启音视频服务
                [YKShell simple:@"killall -9 mediaserverd"];
            }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - 是否在运行进程名称
-(BOOL)isProcessRunning:(NSString *)processName processID:(int *)pid  {
    
    //指定名字参数，按照顺序第一个元素指定本请求定向到内核的哪个子系统，第二个及其后元素依次细化指定该系统的某个部分。
    //CTL_KERN，KERN_PROC,KERN_PROC_ALL 正在运行的所有进程
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL ,0};
    
    
    u_int miblen = 4;
    //值-结果参数：函数被调用时，size指向的值指定该缓冲区的大小；函数返回时，该值给出内核存放在该缓冲区中的数据量
    //如果这个缓冲不够大，函数就返回ENOMEM错误
    size_t size;
    //返回0，成功；返回-1，失败
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    int isRunning = 0;
    
    do
    {
        size += size / 10;
        newprocess = (struct kinfo_proc *)realloc(process, size);
        if (!newprocess)
        {
            if (process)
            {
                free(process);
                process = NULL;
            }
            return isRunning;
        }
        
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0)
    {
        if (size % sizeof(struct kinfo_proc) == 0)
        {
            int nprocess = (int)(size / sizeof(struct kinfo_proc));
            if (nprocess)
            {
                for (int i = nprocess - 1; i >= 0; i--)
                {
                    if(strcmp(process[i].kp_proc.p_comm,processName.UTF8String) == 0){
                        isRunning = 1;
                        
                        if (pid != NULL) {
                            *pid = process[i].kp_proc.p_pid;
                        }
                        break;
                    }
                }
                
                free(process);
                process = NULL;
            }
        }
    }
    
    return isRunning > 0 ? YES : NO;
}
@end

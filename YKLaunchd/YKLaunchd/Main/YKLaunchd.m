//
//  YKLaunchd.m
//  YKLaunchd
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKLaunchd.h"
#import "YKLaunchdLogger.h"
#import "YKLaunchdService.h"

#define yk_runLoopRun                A9a323bc682c36da0923948c39507cb1f2f

@interface YKLaunchd()
+(instancetype)sharedInstance;
-(void)yk_runLoopRun;
@property(nonatomic, strong) YKLaunchdService *service;//服务
@end

@implementation YKLaunchd

+(instancetype)sharedInstance {
    static YKLaunchd *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 运行
-(void)yk_runLoopRun {
    
    _service = [[YKLaunchdService alloc] init];
    CFRunLoopRun();
}
@end



int main(int argc, char * argv[])
{
    
    [[YKLaunchd sharedInstance] yk_runLoopRun];
    return 0;
}

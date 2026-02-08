//
//  YKSBTweakController.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKCommand.h"
#import "YKSBLogger.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "YKSBIPCController.h"
#import "YKSBTweakController.h"


@interface YKSBTweakController()
@property(nonatomic, strong) YKSBIPCController *ipcController;//ipc进程通讯
@end

@implementation YKSBTweakController

+(instancetype)yksb_sharedInstance {
    static YKSBTweakController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        
        _ipcController = [[YKSBIPCController alloc] init];
    }
    return self;
}
@end

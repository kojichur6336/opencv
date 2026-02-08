//
//  YKScreenLockedStatus.m
//  Created on 2025/9/26
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <dlfcn.h>
#import <notify.h>
#import <sys/utsname.h>
#import <objc/message.h>
#import "YKServiceLogger.h"
#import "YKScreenLockedStatus.h"

#define kLockstateNotificationChange "com.apple.springboard.lockstate"

#pragma mark 屏幕状态相关

@implementation YKScreenLockedStatus

-(instancetype)init {
    self = [super init];
    if (self) {
        [self addNotifiLockstate];
    }
    return self;
}


#pragma mark - 添加锁屏状态通知
-(void)addNotifiLockstate {
    
    __weak typeof(self) weakSelf = self;
    int notify_token;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
    notify_register_dispatch(kLockstateNotificationChange, &notify_token, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token) {
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        [weakSelf.delegate screenLockedStatusChanged:state != 0];
    });
#pragma clang diagnostic pop
}

#pragma mark - 主动获取锁屏状态
-(BOOL)fetchCurrentLockState {
    int token;
    uint64_t state = 0;
    
    // 1. 注册一个专门用于查询的 token (不会触发回调)
    // 注意：这里使用 notify_register_check
    uint32_t status = notify_register_check(kLockstateNotificationChange, &token);
    
    if (status == NOTIFY_STATUS_OK) {
        // 2. 获取当前状态
        notify_get_state(token, &state);
        
        // 3. 用完即销毁，防止 token 泄露
        notify_cancel(token);
    }
    
    // state 为 0 通常代表未锁屏，非 0 代表锁屏
    return (state != 0);
}
@end


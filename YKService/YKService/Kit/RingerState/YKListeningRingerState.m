//
//  YKListeningRingerState.m
//  Created on 2026/1/24
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <notify.h>
#import "YKServiceLogger.h"
#import "YKListeningRingerState.h"

#define YK_RINGERSTATE_NOTI_NAME "com.apple.springboard.ringerstate"

@interface YKListeningRingerState()
@property(nonatomic, assign) int notifyToken;
@property(nonatomic, assign, readwrite) BOOL isMuted;
@end

@implementation YKListeningRingerState

-(instancetype)init {
    self = [super init];
    if (self) {
        _notifyToken = -1;
        // 初始化时先获取一次当前状态
        [self updateCurrentState];
        [self startListening];
        
    }
    return self;
}

#pragma mark - 初始化更新状态
-(void)updateCurrentState {
    int token;
    uint64_t state;
    // 仅仅为了读取，注册一个临时的 check token
    notify_register_check(YK_RINGERSTATE_NOTI_NAME, &token);
    notify_get_state(token, &state);
    notify_cancel(token);
    
    // 0 通常代表 Silent Mode (静音)
    // 1 通常代表 Ring Mode (响铃)
    self.isMuted = (state == 0);
}

#pragma mark - 开始监听
-(void)startListening {
    
    if (self.notifyToken != -1) return; // 已经在监听中了

    __weak typeof(self) weakSelf = self;
    
    // 注册全局通知监听
    uint32_t status = notify_register_dispatch(YK_RINGERSTATE_NOTI_NAME,
                                               &_notifyToken,
                                               dispatch_get_main_queue(),
                                               ^(int token) {
        uint64_t state;
        notify_get_state(token, &state);
        
        BOOL newMuteStatus = (state == 0);
        
        // 只有状态真正改变时才发出通知
        if (newMuteStatus != weakSelf.isMuted) {
            weakSelf.isMuted = newMuteStatus;
            [weakSelf.delegate listeningRingerState:weakSelf didUpdateMuteState:newMuteStatus];
        }
    });

    if (status != NOTIFY_STATUS_OK) {
        LOGI(@"[YKSilentMode] 监听注册失败");
    }
}

#pragma mark - 停止监听
-(void)stopListening {
    
    if (self.notifyToken != -1) {
        notify_cancel(self.notifyToken);
        self.notifyToken = -1;
    }
}

- (void)dealloc {
    [self stopListening];
}

@end

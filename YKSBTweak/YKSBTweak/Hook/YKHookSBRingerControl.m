//
//  YKHookSBRingerControl.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2026/1/31.
//

#import "YKSBLogger.h"
#import "YKCommand.h"
#import "YKSBHookHeader.h"
#import "YKSBTweakController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface SBRingerControl : NSObject
@end

SBRingerControl *yk_globalRingerControl = nil;

//============================================================
// SBRingerControl
//============================================================
CHDeclareClass(SBRingerControl);

#pragma mark - 初始化 Hook (适配不同 iOS 版本)
// 适配 iOS 15 及以下版本
CHOptimizedMethod2(self, id, SBRingerControl, initWithHUDController, id, arg1, soundController, id, arg2) {
    self = CHSuper2(SBRingerControl, initWithHUDController, arg1, soundController, arg2);
    yk_globalRingerControl = self;
    return self;
}

// 适配 iOS 16 及以上版本 (横幅管理器的引入)
CHOptimizedMethod2(self, id, SBRingerControl, initWithBannerManager, id, arg1, soundController, id, arg2) {
    self = CHSuper2(SBRingerControl, initWithBannerManager, arg1, soundController, arg2);
    yk_globalRingerControl = self;
    return self;
}


CHConstructor {
    CHLoadLateClass(SBRingerControl);
    CHHook2(SBRingerControl, initWithHUDController, soundController);
    CHHook2(SBRingerControl, initWithBannerManager, soundController);
}
#pragma clang diagnostic pop

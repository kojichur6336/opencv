//
//  YKHookPSGDeviceNameEditingController.m
//  YKUITweak
//
//  Created by liuxiaobin on 2026/1/9.
//

#import <YKXPC/YKXPC.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <YKIPCKey/YKIPCKey.h>
#import "YKHookApplicationMain.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

//============================================================
// PSGDeviceNameEditingController 修改设备名称
//============================================================
CHDeclareClass(PSGDeviceNameEditingController);

CHOptimizedMethod1(self, void, PSGDeviceNameEditingController, viewWillDisappear, BOOL, animated) {
    
    [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE
                                           cmd:YKSBNotificationTypeDeviceNameChanged];
    CHSuper1(PSGDeviceNameEditingController, viewWillDisappear, animated);
}

CHConstructor {
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.apple.Preferences"]) {
        CHLoadLateClass(PSGDeviceNameEditingController);
        CHClassHook1(PSGDeviceNameEditingController, viewWillDisappear);
    }
}

#pragma clang diagnostic pop

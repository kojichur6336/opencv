//
//  YKHookSBBannerManager.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2026/2/3.
//

#import <UIKit/UIKit.h>
#import "YKSBHookHeader.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

//============================================================
// 通知栏窗口 BNBannerSourceListener  SBBannerWindow
//============================================================
CHDeclareClass(BNBannerSourceListener)
CHOptimizedMethod4(self, void, BNBannerSourceListener, __postPresentableWithSpecification, id, arg1, options, id, arg2, userInfo, id, arg3, reply, id, arg4)
{
    NSDictionary *info = arg3;
    NSString *key = @"com.apple.DragUI.druid.DRPasteAnnouncementAccessibilityDescriptionKey";
    
    NSString *content;
    if (@available(iOS 15, *)) {
        content = @"YKService";
    } else {
        content = @"PASTE OCCURRED";
    }
    
    if ([info.allKeys containsObject:key]) {
        NSString *value = info[key];
        if ([value containsString:content]) {
             //do thing
        } else {
            CHSuper4(BNBannerSourceListener, __postPresentableWithSpecification, arg1, options, arg2, userInfo, arg3, reply, arg4);
        }
    } else {
        CHSuper4(BNBannerSourceListener, __postPresentableWithSpecification, arg1, options, arg2, userInfo, arg3, reply, arg4);
    }
}
CHConstructor {
    CHLoadLateClass(BNBannerSourceListener);
    CHClassHook4(BNBannerSourceListener, __postPresentableWithSpecification, options, userInfo,reply);
}


CHDeclareClass(SBAlertItemsController);

CHOptimizedMethod2(self, void, SBAlertItemsController, activateAlertItem, id, arg1, animated, BOOL, arg2)
{
    // 检查arg1对象是否响应alertHeader方法
    if ([arg1 respondsToSelector:@selector(alertHeader)]) {
        // 如果有alertHeader方法，则调用并打印结果
        id alertHeader = [arg1 performSelector:@selector(alertHeader)];
        if ([alertHeader containsString:@"YKService"] || [alertHeader containsString:@"YKScript"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ((void (*)(id, SEL, int))objc_msgSend)(arg1, @selector(dismissIfNecessaryWithResponse:), 1);
            });
        } else {
            CHSuper2(SBAlertItemsController, activateAlertItem, arg1, animated, arg2);
        }
    } else {
        CHSuper2(SBAlertItemsController, activateAlertItem, arg1, animated, arg2);
    }
}

CHConstructor {
    CHLoadLateClass(SBAlertItemsController);
    CHClassHook2(SBAlertItemsController, activateAlertItem,animated);
}
#pragma clang diagnostic pop

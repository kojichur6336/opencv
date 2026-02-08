//
//  YKHookPBAuditTokenInfo.m
//  YKUITweak
//
//  Created by liuxiaobin on 2025/10/22.
//  iOS13: https://github.com/lechium/iOS1351Headers/blob/6bed3dada5ffc20366b27f7f2300a24a48a6284e/usr/libexec/pasted/PBAuditTokenInfo.h#L11
//  iOS14, iOS15: https://github.com/lechium/iPhone_OS_15.5/blob/0f4def7da3cad33a6ea5a4224f4ec3526f3e73f8/usr/libexec/pasted/PBAuditTokenInfo.h#L11
//  iOS16:https://github.com/lechium/iPhoneOS_16.0_20A5303f/blob/f1432fbb84dd339f365fe44c7c4536ba7ca27f1c/usr/libexec/pasted/PBAuditTokenInfo.h#L11

#import <UIKit/UIKit.h>
#import <YKXPC/YKXPC.h>
#import <YKIPCKey/YKIPCKey.h>
#import "YKHookApplicationMain.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


CHDeclareClass(PBAuditTokenInfo);
CHOptimizedMethod1(self, void, PBAuditTokenInfo, setAllowedToPasteUnchecked, BOOL, newVal) {
    
    /*
     绕过用户隐私提示
     当设置为 YES 时：
     App 可以在没有用户明确授权的情况下直接访问或修改剪贴板中的内容。也就是说，用户不会看到提示框，系统默认认为该 App 可信，能够直接进行剪贴板操作。
     当设置为 NO 时：
     系统会显示隐私提示，提醒用户正在进行剪贴板操作，并询问用户是否允许当前 App 访问剪贴板。这是为了保护用户的隐私，避免未经用户同意的敏感数据泄露
     */
    //LOGI(@"setAllowedToPasteUnchecked=%d", newVal);
    CHSuper1(PBAuditTokenInfo, setAllowedToPasteUnchecked, YES);
}



// 判断属性是否存在的函数
BOOL hasMethod(Class class, SEL selector) {
    return class_getInstanceMethod(class, selector) != NULL;
}

CHDeclareClass(PBPasteboardModel);

CHOptimizedMethod3(self, void, PBPasteboardModel, savePasteboard, id, arg1, deviceIslocked, BOOL, arg2, completionBlock, id, arg3)
{
    //LOGI(@"收到了拷贝PBPasteboardModel = %@", arg1);
    
    // 获取 PBItemCollection 类的元数据
    Class itemClass = [arg1 class];
    
    // 使用 runtime 来判断方法是否存在
    SEL bundleIDSelector = @selector(originatorBundleID);
    SEL localizedNameSelector = @selector(originatorLocalizedName);
    
    BOOL hasBundleIDMethod = hasMethod(itemClass, bundleIDSelector);
    BOOL hasLocalizedNameMethod = hasMethod(itemClass, localizedNameSelector);
    
    // 如果方法存在，则调用它们
    NSString *bundleID = @"未知";
    NSString *localizedName = @"未知";
    
    if (hasBundleIDMethod) {
        bundleID = ((NSString *(*)(id, SEL))objc_msgSend)(arg1, bundleIDSelector) ?: @"未知";
    }
    
    if (hasLocalizedNameMethod) {
        localizedName = ((NSString *(*)(id, SEL))objc_msgSend)(arg1, localizedNameSelector) ?: @"未知";
    }
    
    CHSuper3(PBPasteboardModel, savePasteboard, arg1, deviceIslocked, arg2, completionBlock, arg3);
    
    if ([bundleID isEqualToString:@"com.apple.springboard"] || [localizedName isEqualToString: @"YKService"]) {
        LOGI(@"SpringBoard的剪切板不做任何处理 或者 YKService 服务的不做处理");
    } else {
        
        [YKNotificationRequest.shared postWithPort:NOTIFY_PORT_YK_SERVICE
                                               cmd:YKSBNotificationTypeGetPasteboard
                                              data:@{@"appName": localizedName, @"bundleIdentifier": bundleID}];
    }
}


CHConstructor {
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.apple.pasteboard.pasted"])
    {
        CHLoadLateClass(PBAuditTokenInfo);
        CHClassHook1(PBAuditTokenInfo, setAllowedToPasteUnchecked);
        
        CHLoadLateClass(PBPasteboardModel);
        CHClassHook3(PBPasteboardModel, savePasteboard, deviceIslocked, completionBlock);
    }
}

#pragma clang diagnostic pop

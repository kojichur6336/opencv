//
//  YKHookSecureTextEntry.m
//  YKUITweak
//
//  Created by liuxiaobin on 2025/10/30.
//

#import <UIKit/UIKit.h>
#import "YKHookApplicationMain.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

//============================================================
// HOOK密码输入框，让投屏可以看到密码输入的UI
//============================================================
CHDeclareClass(UITextField);

CHOptimizedMethod1(self, void, UITextField, setSecureTextEntry, BOOL, secure) {
    
    CHSuper1(UITextField, setSecureTextEntry, NO);
}

CHConstructor {
    CHLoadLateClass(UITextField);
    CHClassHook1(UITextField, setSecureTextEntry);
}

CHDeclareClass(UITextInputTraits);

CHOptimizedMethod1(self, void, UITextInputTraits, setSecureTextEntry, BOOL, secure) {
    
    CHSuper1(UITextInputTraits, setSecureTextEntry, NO);
}

CHConstructor {
    CHLoadLateClass(UITextInputTraits);
    CHClassHook1(UITextInputTraits, setSecureTextEntry);
}

CHDeclareClass(_UIAlertControllerTextField);

CHOptimizedMethod1(self, void, _UIAlertControllerTextField, setSecureTextEntry, BOOL, secure) {
    
    CHSuper1(_UIAlertControllerTextField, setSecureTextEntry, NO);
}

CHConstructor {
    CHLoadLateClass(_UIAlertControllerTextField);
    CHClassHook1(_UIAlertControllerTextField, setSecureTextEntry);
}


CHDeclareClass(UIFieldEditor);

CHOptimizedMethod1(self, void, UIFieldEditor, setSecureTextEntry, BOOL, secure) {
    
    CHSuper1(UIFieldEditor, setSecureTextEntry, NO);
}

CHConstructor {
    CHLoadLateClass(UIFieldEditor);
    CHClassHook1(UIFieldEditor, setSecureTextEntry);
}


CHDeclareClass(UITextView);

CHOptimizedMethod1(self, void, UITextView, setSecureTextEntry, BOOL, secure) {
    
    CHSuper1(UITextView, setSecureTextEntry, NO);
}

CHConstructor {
    CHLoadLateClass(UITextView);
    CHClassHook1(UITextView, setSecureTextEntry);
}

CHDeclareClass(PSPasscodeField);

CHOptimizedMethod0(self, BOOL, PSPasscodeField, isSecureTextEntry) {
    
    return NO;
}

CHConstructor {
    CHLoadLateClass(PSPasscodeField);
    CHClassHook0(PSPasscodeField, isSecureTextEntry);
}

#pragma clang diagnostic pop

//
//  YKHookSpringBoard.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/14.
//


#import "YKSBLogger.h"
#import "YKCommand.h"
#import "YKSBHookHeader.h"
#import "YKSBTweakController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


//============================================================
// SpringBoard
//============================================================
CHDeclareClass(SpringBoard);

CHOptimizedMethod1(self, void, SpringBoard, applicationDidFinishLaunching, id, application) {
  
    CHSuper1(SpringBoard, applicationDidFinishLaunching, application);
    [YKSBTweakController yksb_sharedInstance];
}


CHConstructor {
    CHLoadLateClass(SpringBoard);
    CHClassHook1(SpringBoard, applicationDidFinishLaunching);
}
#pragma clang diagnostic pop

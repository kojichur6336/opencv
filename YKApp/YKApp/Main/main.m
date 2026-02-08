//
//  main.m
//  YKApp
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <UIKit/UIKit.h>
#import "YKDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([YKDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

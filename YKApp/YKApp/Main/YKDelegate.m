//
//  YKDelegate.m
//  YKApp
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKToast.h"
#import "YKDelegate.h"
#import "YKAppController.h"

@interface YKDelegate()
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) YKAppController *rootViewController;
@end

@implementation YKDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.rootViewController = [[YKAppController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.rootViewController];
    self.navigationController.navigationBarHidden = YES;
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    [YKToast configToast];
    return YES;
}
@end

//
//  YKToast.m
//  YKApp
//
//  Created by liuxiaobin on 2025/11/3.
//

#import "YKToast.h"
#import <YKHUD/YKProgressHUD.h>

@implementation YKToast

#pragma mark - 默认配置
+(void)configToast
{
    [YKProgressHUD setMinimumSize:CGSizeMake(120, 120)];
    [YKProgressHUD setShouldTintImages:false];
    [YKProgressHUD setCornerRadius:6];
    [YKProgressHUD setForegroundColor:[UIColor.blackColor colorWithAlphaComponent:0.7]];
    [YKProgressHUD setBackgroundColor:[UIColor.blackColor colorWithAlphaComponent:0.7]];
    [YKProgressHUD setDefaultStyle:YKProgressHUDStyleDark];
    [YKProgressHUD setDefaultMaskType:YKProgressHUDMaskTypeClear];
    [YKProgressHUD setDefaultAnimationType:YKProgressHUDAnimationTypeNative];
    [YKProgressHUD setMinimumDismissTimeInterval:2];
    [YKProgressHUD setMaximumDismissTimeInterval:2];
}

#pragma mark - 显示加载
+(void)showWithStatus:(NSString *)msg
{
    [YKProgressHUD setMinimumSize:CGSizeMake(120, 80)];
    [YKProgressHUD resetOffsetFromCenter];
    [YKProgressHUD setDefaultStyle:YKProgressHUDStyleDark];
    [YKProgressHUD setDefaultMaskType:YKProgressHUDMaskTypeClear];
    [YKProgressHUD setDefaultAnimationType:YKProgressHUDAnimationTypeNative];
    [YKProgressHUD showWithStatus:msg];
}

#pragma mark - 隐藏
+(void)dismiss {
    [YKProgressHUD dismiss];
}
@end

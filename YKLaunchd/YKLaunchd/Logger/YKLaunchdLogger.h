//
//  YKLaunchdLogger.h
//  YKLaunchd
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <Foundation/Foundation.h>

#if YKLogMode == 0
#define LOGI(...) (void)0
#else
#define LOGI(fmt, ...) NSLog((@"[YKLaunchd] " fmt), ##__VA_ARGS__)
#endif


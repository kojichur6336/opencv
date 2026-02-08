//
//  YKSBLogger.h
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <Foundation/Foundation.h>


#if YKLogMode == 0
#define LOGI(...) (void)0
#else
#define LOGI(fmt, ...) NSLog((@"[YKSBTweak] " fmt), ##__VA_ARGS__)
#endif

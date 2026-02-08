//
//  YKServiceLogger.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKServiceFileLogger.h"
#import <Foundation/Foundation.h>


#if YKLogMode == 0
#define LOGI(...) (void)0
#elif YKLogMode == 1
#define LOGI(fmt, ...) NSLog((@"[YKService] " fmt), ##__VA_ARGS__)
#elif YKLogMode == 2
#define LOGI(fmt, ...) [YKSEFileLog write:[NSString stringWithFormat:(fmt), ##__VA_ARGS__]]
#endif

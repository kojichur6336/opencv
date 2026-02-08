//
//  YKAppLogger.h
//  Created on 2025/10/10
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if YKLogMode == 0
#define LOGI(...) (void)0
#else
#define LOGI(fmt, ...) NSLog((@"[YKApp] " fmt), ##__VA_ARGS__)
#endif

NS_ASSUME_NONNULL_END

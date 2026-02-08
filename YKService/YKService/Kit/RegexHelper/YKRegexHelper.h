//
//  YKRegexHelper.h
//  Created on 2025/10/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 正则表达式
@interface YKRegexHelper : NSObject


/// 判断字符串是否包含中文
/// - Parameter string: 字符串
+(BOOL)stringContainsChinese:(NSString *)string;

@end

NS_ASSUME_NONNULL_END

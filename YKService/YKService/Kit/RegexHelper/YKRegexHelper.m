//
//  YKRegexHelper.m
//  Created on 2025/10/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKRegexHelper.h"

@implementation YKRegexHelper

#pragma mark - 是否包含中文
+(BOOL)stringContainsChinese:(NSString *)string {
    if (string.length == 0) return NO;

    // 中文汉字的 Unicode 范围 \u4e00-\u9fff
    NSString *pattern = @"[\u4e00-\u9fff]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSRange range = NSMakeRange(0, string.length);
    NSUInteger matchCount = [regex numberOfMatchesInString:string options:0 range:range];
    return matchCount > 0;
}
@end

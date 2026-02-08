//
//  YKColor.m
//  Created on 2025/10/10
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKColor.h"

@implementation UIColor (YKColor)

+ (UIColor *)mainColor {
    return UIColor.redColor;
}

+ (UIColor *)bgColor {
    return [UIColor hexadecimalWithRGB:0xefefef alpha:1.0];
}

+ (UIColor *)lineColor {
    return [UIColor rgbWithR:216 g:216 b:216 alpha:1.0];
}

+ (UIColor *)rgbWithR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
}

+ (UIColor *)hexadecimalWithRGB:(NSInteger)rgb alpha:(CGFloat)alpha {
    CGFloat red = ((rgb >> 16) & 0xFF) / 255.0;
    CGFloat green = ((rgb >> 8) & 0xFF) / 255.0;
    CGFloat blue = (rgb & 0xFF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // 去除前缀
    if ([cString hasPrefix:@"0X"]) {
        cString = [cString substringFromIndex:2];
    }
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }
    
    if ([cString length] != 6) {
        return [UIColor clearColor];
    }
    
    // 分割成 r, g, b 三段
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:(CGFloat)r/255.0
                           green:(CGFloat)g/255.0
                            blue:(CGFloat)b/255.0
                           alpha:1.0];
}

@end


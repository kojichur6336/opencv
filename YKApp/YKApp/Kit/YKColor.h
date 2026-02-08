//
//  YKColor.h
//  Created on 2025/10/10
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (YKColor)

/// 主色调
@property (class, nonatomic, readonly) UIColor *mainColor;

/// 统一背景颜色
@property (class, nonatomic, readonly) UIColor *bgColor;

/// 线颜色
@property (class, nonatomic, readonly) UIColor *lineColor;

/// RGB 创建颜色
/// @param r 红色 (0~255)
/// @param g 绿色 (0~255)
/// @param b 蓝色 (0~255)
/// @param alpha 透明度
+ (UIColor *)rgbWithR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b alpha:(CGFloat)alpha;

/// 16进制颜色
/// @param rgb 16进制整数
/// @param alpha 透明度
+ (UIColor *)hexadecimalWithRGB:(NSInteger)rgb alpha:(CGFloat)alpha;

/// 通过16进制字符串创建颜色（如 @"#23A0EF" 或 @"0x23A0EF"）
+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END

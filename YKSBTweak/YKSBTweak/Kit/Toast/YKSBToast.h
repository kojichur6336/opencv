//
//  YKSBToast.h
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/17.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 吐司类
@interface YKSBToast : NSObject

/// 显示消息
/// - Parameter message: message
+(void)showMessage:(NSString *)message;

/// 显示消息
/// - Parameters:
///   - message: 显示消息
///   - position: 位置
///   - duration: 时间
+(void)showMessage:(NSString *)message point:(CGPoint)position duration:(int)duration;


/// 屏幕将要旋转
/// - Parameter toInterfaceOrientation: toInterfaceOrientation
+(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
@end

NS_ASSUME_NONNULL_END

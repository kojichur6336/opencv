//
//  YKOrientationObserver.h
//  YKService
//
//  Created by liuxiaobin on 2025/12/4.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#define YKOrientationObserver                              A5772b59e93cd42329bee4dfc10965362al
#define YKOrientationObserverDelegate                      B833c55yjb0ce35724cac5fd18d58bb749c
#define didChangeOrientation                               Cc738aa22x10bb7ead55131244b078798da


@protocol YKOrientationObserverDelegate <NSObject>

/// 当屏幕方向发生变化时的回调
/// @param orientation 当前屏幕方向
-(void)didChangeOrientation:(UIInterfaceOrientation)orientation;
@end


/// MARK - 远控方向监听
@interface YKOrientationObserver : NSObject

/// 初始化
/// - Parameter delegate: 委托
-(instancetype)initWithDelegate:(id<YKOrientationObserverDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END

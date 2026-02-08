//
//  YKToast.h
//  YKApp
//
//  Created by liuxiaobin on 2025/11/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 显示对话框
@interface YKToast : NSObject


/// 配置吐司
+(void)configToast;


/// 显示加载
/// - Parameter msg: 提示语
+(void)showWithStatus:(NSString *)msg;



/// 隐藏
+(void)dismiss;
@end

NS_ASSUME_NONNULL_END

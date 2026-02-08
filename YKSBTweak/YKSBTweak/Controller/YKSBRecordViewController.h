//
//  YKSBRecordViewController.h
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/12/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKSBRecordViewController           Abee63af5dc516172cb437dc1822916893f

/// MARK - 录制倒计时控制器
@interface YKSBRecordViewController : NSObject

#pragma mark - 显示
+(void)show:(void (^)(void))completion;


+(void)hidden;
@end

NS_ASSUME_NONNULL_END

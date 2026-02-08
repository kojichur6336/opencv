//
//  YKKBDManager.h
//  YKService
//
//  Created by liuxiaobin on 2026/1/23.
//

#import <Foundation/Foundation.h>

#define YKKBDManager                 A0713f5188ab8938376bbc0860bd87952cc


NS_ASSUME_NONNULL_BEGIN

/// MARK - 键盘Kbd服务管理类
@interface YKKBDManager : NSObject
@property(nonatomic, readonly) BOOL isChineseInput;//是否中文输入


/// 向 iOS 系统键盘数据库添加自定义短语（文本替换）
/// - Parameters:
///   - shortcut: 快捷输入码（触发词），例如 @"ykcjsr"
///   - phrase: 对应的完整长短语（目标词），例如 @"超级输入法"
///   - return 执行成功返回 YES，如果数据库无法打开或 SQL 执行失败则返回 NO。
-(BOOL)addShortcut:(NSString *)shortcut phrase:(NSString *)phrase;


/// 输入文本
/// - Parameter text: 文本
-(void)inputText:(NSString *)text;


/// 更新变化
-(void)applyChanges;
@end

/*
BOOL result = [self.kbdManager addShortcut:@"ykc" phrase:@"这个是一个利用短语的超级输入法"];
if (result) {
    [self.kbdManager applyChanges];
    usleep(100 * 1000);
    [self handleEvent_keyboard:@{@"data": @{@"key": @"y"}} yksr_device: nil];
    usleep(100 * 1000);
    [self handleEvent_keyboard:@{@"data": @{@"key": @"k"}} yksr_device: nil];
    usleep(50 * 1000);
    [self handleEvent_keyboard:@{@"data": @{@"key": @"c"}} yksr_device: nil];
    usleep(50 * 1000);
    [self handleEvent_keyboard:@{@"data": @{@"key": @"Space"}} yksr_device: nil];
}
*/

NS_ASSUME_NONNULL_END

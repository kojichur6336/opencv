//
//  YKSimulator.h
//  YKSimulatorTouch
//
//  Created by xiaobin liu on 2024/6/14.
//

#import "YKTouch.h"
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


/// MARK - 模拟类
@interface YKSimulator : NSObject


/// 获取键码
/// @param keyCode 键盘码 具体查看 MKKeyMap 类
+(int)getKeyCode:(NSString *)keyCode;


/// 执行键盘按键事件
/// @param code 键盘码 具体查看 MKKeyMap 类
/// @param action 动作 (KEYPRESS 0) (KEYDOWN 1) (KEYUP 2)
+(void)keyPressCode:(int)code action:(int)action;


/// 模拟触摸按下事件
/// @param point 触摸点的坐标
/// @param fingerId 触摸手指的唯一标识符
+(void)touchDown: (CGPoint)point fingerId:(int)fingerId;


/// 模拟触摸移动事件
/// @param point 位置
/// @param fingerId 触摸手指的唯一标识符
/// @param duration 持续时间
+(void)touchMove: (CGPoint)point fingerId:(int)fingerId duration:(int)duration;


/// 模拟触摸移动事件
/// @param point 位置
/// @param fingerId 触摸手指的唯一标识符
/// @param duration 持续时间
+(void)touchMoveEx:(CGPoint)point fingerId:(int)fingerId duration:(int)duration;


/// 模拟触摸移动事件
/// @param point 位置
/// @param fingerId 触摸手指的唯一标识符
/// @param duration 持续时间
+(void)touchMoveEx2:(CGPoint)point fingerId:(int)fingerId duration:(int)duration;


/// 模拟触摸弹起事件
/// @param fingerId 触摸手指的唯一标识符
+(void)touchUp:(int)fingerId;

/// 模拟触摸弹起事件
/// @param point 位置
/// @param fingerId 触摸手指的唯一标识符
+(void)touchUp:(CGPoint)point fingerId:(int)fingerId;


/// 点击
/// @param point 位置
/// @param duration 持续时间
+(void)tap:(CGPoint)point duration:(int)duration;

/// 滑动
/// @param fromPoint 开始位置
/// @param toPoint 结束位置
/// @param duration 持续时间
+(void)swipe:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration;


/// 随机点击
/// @param point 位置
/// @param randomTime 随机时间
+(CGPoint)randomTap:(CGPoint)point randomTime:(int)randomTime;


/// 随机真实点击带抖动
/// @param point 位置
/// @param randomTime 随机时间
+(CGPoint)randomsTap:(CGPoint)point randomTime:(int)randomTime;


/// 放大
/// @param fromPoint 开始位置
/// @param toPoint 结束位置
/// @param duration 时间单位毫秒 默认值为50
+(void)zoomIn:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration;


/// 捏合
/// @param fromPoint 开始位置
/// @param toPoint 结束位置
/// @param duration 时间单位毫秒 默认值为50
+(void)zoomOut:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration;


/// 获取当前触摸数量
+(int)getCurrentTouchCount;


/// 发送多组数据
/// - Parameter touchs: touchs
+(void)performTouchFromRawData:(NSArray<YKTouch *> *)touchs;


/// 终止当前的触摸移动操作
+(void)clear;


//============================================================
// 主屏幕键 (Home Button / Menu)(已验证✅)
//============================================================

/**
 * 模拟单击一次 Home 键。
 * 常用于从 App 返回主屏幕。
 */
+(void)menuPress;

/**
 * 模拟双击 Home 键。
 * 总耗时：约 0.25 秒。
 * 计算公式：0.05 (第一次) + 0.15 (停顿) + 0.05 (第二次) = 0.25s。
 * 在真机上，这通常会唤起“多任务管理界面”（App Switcher）。
 */
+(void)menuDoublePress;


/**
 * 模拟单击电源键。
 */
+(void)powerPress;


/// 按下静音键
+(void)mutePress;


/// 音量+
+(void)volupPress;


/// 音量减
+(void)voldownPress;


/// 屏幕截图
+(void)snapshotPress;


/// 搜索界面
+(void)toggleSpotlight;


/// 屏幕亮度+
+(void)displayBrightnessIncrementPress;


/// 屏幕亮度-
+(void)displayBrightnessDecrementPress;


/// 黏贴
+(void)pastePress;
@end

NS_ASSUME_NONNULL_END

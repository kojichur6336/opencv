//
//  YKSimulator.m
//  YKSimulatorTouch
//
//  Created by xiaobin liu on 2024/6/14.
//

#import "YKTouch.h"
#import "YKKeyMap.h"
#import <UIKit/UIKit.h>
#import "YKSimulator.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach/mach_time.h>
#import "YKServiceLogger.h"
#import <IOKit/hid/IOHIDEvent.h>
#import <IOKit/hid/IOHIDEvent7.h>
#import <IOKit/hid/IOHIDEventTypes7.h>
#import <IOKit/hid/IOHIDEventSystemClient.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


/**
 * HID 使用页面 (Usage Pages) 枚举
 * 对应 USB HID 规范，定义了设备上报的数据属于哪种类型
 */
enum {
    kHIDPage_KeyboardOrKeypad       = 0x07, // 标准键盘或小键盘页
    kHIDPage_Telephony              = 0x0B, // 电话相关控制（如接听、挂断）
    kHIDPage_Consumer               = 0x0C, // 消费电子设备页（如多媒体控制键：播放/暂停、音量）
    kHIDPage_VendorDefinedStart     = 0xFF00 // 厂商自定义扩展页起始地址
};


/**
 * 消费电子设备用途页 (Consumer Usage Page - 0x0C) 键值定义
 * 对应多媒体键、电源键、音量键等
 */
enum {
    kHIDUsage_Csmr_Power              = 0x30,          // 电源键 (开/关控制)
    kHIDUsage_Csmr_Menu               = 0x40,          // 菜单键 (iOS 中通常对应 Home 键)
    kHIDUsage_Csmr_Snapshot           = 0x65,          // 快照/截图 (单次触发)
    
    kHIDUsage_Csmr_DisplayBrightnessIncrement = 0x6F,  // 调高屏幕亮度
    kHIDUsage_Csmr_DisplayBrightnessDecrement = 0x70,  // 调低屏幕亮度
    
    kHIDUsage_Csmr_Play               = 0xB0,          // 播放
    kHIDUsage_Csmr_Pause              = 0xB1,          // 暂停
    kHIDUsage_Csmr_FastForward        = 0xB3,          // 快进
    kHIDUsage_Csmr_Rewind             = 0xB4,          // 快退
    kHIDUsage_Csmr_ScanNextTrack      = 0xB5,          // 下一曲
    kHIDUsage_Csmr_ScanPreviousTrack  = 0xB6,          // 上一曲
    kHIDUsage_Csmr_Stop               = 0xB7,          // 停止
    kHIDUsage_Csmr_Eject              = 0xB8,          // 弹出 (Eject)
    kHIDUsage_Csmr_StopOrEject        = 0xCC,          // 停止/弹出
    kHIDUsage_Csmr_PlayOrPause        = 0xCD,          // 播放/暂停
    
    kHIDUsage_Csmr_Mute               = 0xE2,          // 静音
    kHIDUsage_Csmr_VolumeIncrement    = 0xE9,          // 调高音量
    kHIDUsage_Csmr_VolumeDecrement    = 0xEA,          // 调低音量
    
    kHIDUsage_Csmr_ALKeyboardLayout   = 0x1AE,         // 切换键盘布局 (Application Launcher)
    kHIDUsage_Csmr_ACSearch           = 0x221,         // 搜索 (App Control)
    kHIDUsage_Csmr_ACLock             = 0x26B,         // 锁定屏幕 (App Control)
    kHIDUsage_Csmr_ACUnlock           = 0x26C,         // 解锁屏幕 (App Control)
};



IOHIDEventSystemClientRef ioHIDEventSystemForSenderID;
static BOOL stopTouchMove = NO;  // 定义一个全局静态变量来控制中止操作

// 定义最多支持的手指索引数量。可以同时追踪的手指触摸事件数量上限为 21(索引做大值为20)。
#define MAX_FINGER_INDEX 21

// 触摸事件的状态标记：表示当前没有有效的触摸事件。
#define NOT_VALID 0

// 触摸事件的状态标记：表示当前的触摸事件有效且需要处理。
#define VALID 1

// 触摸事件的状态标记：表示当前的触摸事件将在下一次 append 操作后标记为有效。
#define VALID_AT_NEXT_APPEND 2

// 定义二维数组中的索引，用于标识触摸事件的状态字段。
#define EVENT_VALID_INDEX 0

// 定义二维数组中的索引，用于存储触摸事件的类型字段。
// 例如，触摸事件类型可能是 DOWN、MOVE 或 UP。
#define EVENT_TYPE_INDEX 1

// 定义二维数组中的索引，用于存储触摸事件的 X 坐标。
#define EVENT_X_INDEX 2

// 定义二维数组中的索引，用于存储触摸事件的 Y 坐标。
#define EVENT_Y_INDEX 3

static int eventsToAppend[MAX_FINGER_INDEX][4];//用于存储最多 20 个手指（MAX_FINGER_INDEX）的触摸事件状态和数据

static int currentTouchIndex = 0; // 当前触摸事件索引


static const NSTimeInterval fingerLiftDelay = 0.05;
static const NSTimeInterval multiTapInterval = 0.15;
static const NSTimeInterval fingerMoveInterval = 0.016;
static const NSTimeInterval longPressHoldDelay = 2.0;
static const IOHIDFloat defaultMajorRadius = 5;
static const IOHIDFloat defaultPathPressure = 0;
static const long nanosecondsPerSecond = 1e9;

@implementation YKSimulator


#pragma mark - 获取键码
+(int)getKeyCode:(NSString *)keyCode
{
    return [YKKeyMap getCode:keyCode];
}

#pragma mark - 键盘模拟按下
+(void)keyPressCode:(int)code action:(int)action {
    
    if (code == -1)
    {
        return;
    }

    switch (action) {
        case 0: {
            [self _sendIOHIDKeyboardEvent:kHIDPage_KeyboardOrKeypad usage:code isKeyDown:YES];
            [self _sendIOHIDKeyboardEvent:kHIDPage_KeyboardOrKeypad usage:code isKeyDown:NO];
        }
            break;
        case 1: {
            [self _sendIOHIDKeyboardEvent:kHIDPage_KeyboardOrKeypad usage:code isKeyDown:YES];
        }
            break;
        case 2: {
            [self _sendIOHIDKeyboardEvent:kHIDPage_KeyboardOrKeypad usage:code isKeyDown:NO];
        }
            break;
        default:
            break;
    }
}


#pragma mark - 发送键盘事件
+(void)_sendIOHIDKeyboardEvent:(uint32_t)page usage:(uint32_t)usage isKeyDown:(boolean_t)isKeyDown {
    
    uint64_t abTime = mach_absolute_time();
    AbsoluteTime timeStamp = *(AbsoluteTime *)&abTime;
    IOHIDEventRef eventRef = IOHIDEventCreateKeyboardEvent(kCFAllocatorDefault,
                                                           timeStamp,
                                                           page,
                                                           usage,
                                                           isKeyDown,
                                                           0);
    postIOHIDEvent(eventRef);
    CFRelease(eventRef);
}



//============================================================
// 模拟触摸
//============================================================
#pragma 生成Touch事件
+(YKTouch *)generateYKTouch:(CGPoint)point fingerId:(int)fingerId touchType: (YKTouchType)type {
    
    YKTouch *touch = [[YKTouch alloc] init];
    touch.type = type;
    touch.fingerId = fingerId;
    touch.point = point;
    return touch;
}

#pragma mark - 模拟触摸
+(void)touchDown:(CGPoint)point fingerId:(int)fingerId {
    
    currentTouchIndex ++;
    [self forceTouchUpIfNeeded:fingerId];
    YKTouch *touch = [self generateYKTouch:point fingerId:fingerId touchType:YKTouchTypeDOWN];
    performTouchFromRawData(@[touch]);
    
}

#pragma mark - 触摸移动
+(void)touchMove:(CGPoint)point fingerId:(int)fingerId duration:(int)duration {
    
    if (eventsToAppend[fingerId][EVENT_VALID_INDEX] == VALID) {
        YKTouch *touch = [self generateYKTouch:point fingerId:fingerId touchType:YKTouchTypeMOVE];
        performTouchFromRawData(@[touch]);
        if (duration != 0) {
            usleep(duration * 1000);
        }
    } else {
        [[YKServiceFileLogger sharedInstance] write:[NSString stringWithFormat:@"没有TouchDown就直接Move, ID = %d",fingerId]];
    }
}


#pragma mark - 触摸移动扩展
+(void)touchMoveEx:(CGPoint)point fingerId:(int)fingerId duration:(int)duration {
    
    stopTouchMove = NO;  // 在操作开始时重置中止标志
    YKTouch *lastTouchObject = [self findYKTouchByFingerId:fingerId];
    if (lastTouchObject) {
        // 该fingerId上一次的坐标
        CGPoint fromPoint = lastTouchObject.point;
        
        // 计算起始点到目标点的直线距离
        int distance = sqrt(pow((point.x-fromPoint.x), 2) + pow((point.y-fromPoint.y), 2));
        // 如果距离为零，则无需进行移动操作，直接返回
        if (distance == 0) {
            return;
        }
        // 根据指定的持续时间和距离，计算出移动操作需要分成的段数
        // 这里取距离除以5和持续时间除以20的较小值作为段数，以保证移动不会太快
        int d = MIN(distance/5, duration/25);
        
        // 计算每个段中横向和纵向移动的步长
        float perX = floor((point.x - fromPoint.x) / d);
        float perY = floor((point.y - fromPoint.y) / d);
        
        //初始化移动点为起始点
        CGPoint movePoint = fromPoint;
        
        // 使用循环逐步移动触摸点
        for (int i=0; i<d; i++)
        {
            // 更新移动点的位置
            movePoint = CGPointMake(movePoint.x + perX, movePoint.y + perY);
            if (stopTouchMove) {
                return;
            } else {
                YKTouch *touch = [self generateYKTouch:movePoint fingerId:fingerId touchType:YKTouchTypeMOVE];
                performTouchFromRawData(@[touch]);
                // 等待一段时间间隔，控制移动速度
                usleep(duration / d * 1000);
            }
        }
        
        // 最后一步确保移动到目标点
        YKTouch *touch = [self generateYKTouch:point fingerId:fingerId touchType:YKTouchTypeMOVE];
        performTouchFromRawData(@[touch]);
    }
}

#define MIN_VALUE 1e-4
#define IS_FLOAT_ZERO(d) (fabs(d) < MIN_VALUE)
#define DISTANCE(x1,y1,x2,y2) sqrt( pow((x1-x2),2 )+ pow((y1-y2),2 ))
#pragma mark - 模拟触摸移动事
+(void)touchMoveEx2:(CGPoint)point fingerId:(int)fingerId duration:(int)duration
{
    stopTouchMove = NO;  // 在操作开始时重置中止标志
    YKTouch *lastTouchObject = [self findYKTouchByFingerId:fingerId];
    if (lastTouchObject)
    {
        // 获取上一次的坐标
        CGPoint fromPoint = lastTouchObject.point;
        bool bOne_Step = false;
        float step_distance = 40.0; // 每次移动的步长
        
        // 计算当前点与上一次点之间的距离
        float distance = DISTANCE(point.x, point.y, fromPoint.x, fromPoint.y);
        
        // 如果距离非常小，则认为已经到达目标点
        if (IS_FLOAT_ZERO(distance)) {
            return;
        }
        
        // 如果距离小于设定的步长，则调整步长为当前距离
        if (distance < step_distance) {
            step_distance = distance;
            bOne_Step = true;
        }
        
        // 计算移动方向的角度
        float sita = NAN;
        float k = 0.0;
        if (point.x != fromPoint.x) {
            k = -(point.y - fromPoint.y) / (point.x - fromPoint.x);
            sita = atan(k);
            if (point.y < fromPoint.y && point.x < fromPoint.x) {
                sita -= M_PI;
            } else if (point.y > fromPoint.y && point.x < fromPoint.x) {
                sita += M_PI;
            }
        }
        
        // 计算总步数
        float total_step = floor(distance / step_distance);
        float interval = duration / total_step; // 每步的时间间隔
        
        int current_step = 0;
        int all_step = total_step + 1; // 包含终点的步数
        
        do {
            // 计算下一步的坐标增量
            float newx = step_distance;
            float newy = step_distance;
            if (fromPoint.x > point.x) {
                newx = -newx;
            }
            if (fromPoint.y > point.y) {
                newy = -newy;
            }
            if (isnan(sita)) {
                newx = 0.0;
            } else if (IS_FLOAT_ZERO(k)) {
                newy = 0.0;
            } else {
                newx = cos(sita) * step_distance;
                newy = -sin(sita) * step_distance;
            }
            
            // 计算新的触摸点
            CGPoint newpoint = CGPointMake(bOne_Step ? point.x : fromPoint.x + newx,
                                           bOne_Step ? point.y : fromPoint.y + newy);
            
            // 判断是否停止
            if (stopTouchMove) {
                return;
            }
            
            // 更新触摸状态为移动
            YKTouch *touch = [self generateYKTouch:newpoint fingerId:fingerId touchType:YKTouchTypeMOVE];
            performTouchFromRawData(@[touch]);// 发送触摸事件
            
            
            usleep(interval * 1000); // 休眠以控制移动速度
            
            // 更新原点和距离
            fromPoint = newpoint;
            float distance = DISTANCE(point.x, point.y, fromPoint.x, fromPoint.y );
            
            // 如果距离接近0，则认为移动结束
            if (IS_FLOAT_ZERO(distance)) {
                break;
            }
            if (distance < step_distance) {
                step_distance = distance;
                bOne_Step = true;
            }
            
            ++current_step;
            if (current_step > all_step) {
                break;
            }
            
        } while (true);
        
    }
}

#pragma mark - 模拟弹起来的触摸事件
+(void)touchUp:(int)fingerId
{
    YKTouch *lastTouchObject = [self findYKTouchByFingerId:fingerId];
    if (lastTouchObject)
    {
        currentTouchIndex --;
        YKTouch *touch = [self generateYKTouch:lastTouchObject.point fingerId:fingerId touchType:YKTouchTypeUP];
        performTouchFromRawData(@[touch]);
    }
}

#pragma mark - 模拟弹起
+(void)touchUp:(CGPoint)point fingerId:(int)fingerId {
    
    if (eventsToAppend[fingerId][EVENT_VALID_INDEX] == VALID) {
        
        currentTouchIndex --;
        YKTouch *touch = [self generateYKTouch:point fingerId:fingerId touchType:YKTouchTypeUP];
        performTouchFromRawData(@[touch]);
    } else {
        [[YKServiceFileLogger sharedInstance] write:[NSString stringWithFormat:@"没有TouchDown就直接Up, ID = %d",fingerId]];
    }
}


#pragma mark - 模拟点击
+(void)tap:(CGPoint)point duration:(int)duration {
    
    [self touchDown:point fingerId:0];
    usleep(duration * 1000);
    [self touchUp:point fingerId:0];
}

#pragma mark - 滑动点击
+(void)swipe:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration {
    
    [self touchDown:fromPoint fingerId:0];
    [self touchMoveEx:toPoint fingerId:0 duration:duration];
    [self touchUp:toPoint fingerId:0];
}

#pragma mark - 发送一组
+(void)performTouchFromRawData:(NSArray<YKTouch *> *)touchs {
    performTouchFromRawData(touchs);
}

#pragma mark - 随机点击
+(CGPoint)randomTap:(CGPoint)point randomTime:(int)randomTime {
    
    if (randomTime == 0) {
        randomTime = 5;
    }
    int nXBig,nXSmall,nYBig,nYSmall;
    nXBig = point.x + randomTime;
    nXSmall = point.x - randomTime;
    nYBig = point.y + randomTime;
    nYSmall = point.y - randomTime;
    
    int nXRandom = [self getRandomNumberFrom:nXSmall to:nXBig];
    int nYRandom = [self getRandomNumberFrom:nYSmall to:nYBig];
    
    CGPoint newPoint = CGPointMake(nXRandom, nYRandom);
    
    [self touchDown:newPoint fingerId:0];
    [self touchUp:newPoint fingerId:0];
    return newPoint;
}

#pragma mark - 随机真实带抖动
+(CGPoint)randomsTap:(CGPoint)point randomTime:(int)randomTime {
    
    if (randomTime == 0) {
        randomTime = 5;
    }
    int nXBig,nXSmall,nYBig,nYSmall;
    nXBig = point.x + randomTime;
    nXSmall = point.x - randomTime;
    nYBig = point.y + randomTime;
    nYSmall = point.y - randomTime;
    
    int nXRandom = [self getRandomNumberFrom:nXSmall to:nXBig];
    int nYRandom = [self getRandomNumberFrom:nYSmall to:nYBig];
    
    
    CGPoint newPoint = CGPointMake(nXRandom, nYRandom);
    int iFid =[self getRandomNumberFrom:5 to:20];
    
    [self touchDown:newPoint fingerId:iFid];
    [self touchMove:newPoint fingerId:iFid duration:100];
    [self touchUp:newPoint fingerId:iFid];
    return newPoint;
}

#pragma mark - 放大
+(void)zoomIn:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration {
    
    if (duration == 0)
        duration = 50;
    
    // 计算两个触摸点的中间点
    CGPoint centerPoint = CGPointMake((fromPoint.x + toPoint.x) / 2, (fromPoint.y + toPoint.y) / 2);
    
    // 计算两个触摸点之间的距离
    float distance = sqrt(pow(toPoint.x - fromPoint.x, 2) + pow(toPoint.y - fromPoint.y, 2));
    
    // 根据指定的持续时间和距离，计算出移动操作需要分成的段数
    // 这里取距离除以5和持续时间除以20的较小值作为段数，以保证移动不会太快
    int steps = MIN(distance / 5, duration / 20);
    if (steps == 0) steps = 2; // 防止除以0的情况
    
    
    // 开始确保手指保持一定距离
    float startDistance = 10.0; // 最终距离可以根据需要调整
    float angle = atan2(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x);
    CGPoint point1 = CGPointMake(centerPoint.x - startDistance / 2 * cos(angle), centerPoint.y - startDistance / 2 * sin(angle));
    CGPoint point2 = CGPointMake(centerPoint.x + startDistance / 2 * cos(angle), centerPoint.y + startDistance / 2 * sin(angle));
    
    // 创建按下（DOWN）事件
    YKTouch *touch1 = [self generateYKTouch:point1 fingerId:14 touchType:YKTouchTypeDOWN];
    YKTouch *touch2 = [self generateYKTouch:point2 fingerId:15 touchType:YKTouchTypeDOWN];
    performTouchFromRawData(@[touch1,touch2]);
    
    
    // 逐步移动两根手指
    for (int i = 0; i < steps; i++) {
        
        if (i + 1 == steps)
        {
            // 最后一步直接设置为目标点，以防止浮点数计算误差
            point1 = fromPoint;
            point2 = toPoint;
        } else {
            // 动态计算移动方向并更新点的位置
            float deltaX1 = (fromPoint.x - point1.x) / (steps - i);
            float deltaY1 = (fromPoint.y - point1.y) / (steps - i);
            float deltaX2 = (toPoint.x - point2.x) / (steps - i);
            float deltaY2 = (toPoint.y - point2.y) / (steps - i);
            
            point1.x += deltaX1;
            point1.y += deltaY1;
            
            point2.x += deltaX2;
            point2.y += deltaY2;
        }
        
        // 生成新的MOVE事件
        YKTouch *moveTouch1 = [self generateYKTouch:point1 fingerId:14 touchType:YKTouchTypeMOVE];
        YKTouch *moveTouch2 = [self generateYKTouch:point2 fingerId:15 touchType:YKTouchTypeMOVE];
        
        // 执行MOVE事件
        performTouchFromRawData(@[moveTouch1,moveTouch2]);
        usleep(1000 * duration / steps); // 控制每一步的移动速度
    }
    
    // 最后一步确保移动到目标点
    YKTouch *finalTouch1 = [self generateYKTouch:fromPoint fingerId:14 touchType:YKTouchTypeMOVE];
    YKTouch *finalTouch2 = [self generateYKTouch:toPoint fingerId:15 touchType:YKTouchTypeMOVE];
    
    // 执行最终MOVE事件
    performTouchFromRawData(@[finalTouch1,finalTouch2]);
    
    // 创建抬起（UP）事件
    YKTouch *touchUp1 = [self generateYKTouch:fromPoint fingerId:14 touchType:YKTouchTypeUP];
    YKTouch *touchUp2 = [self generateYKTouch:toPoint fingerId:15 touchType:YKTouchTypeUP];
    // 执行抬起事件
    performTouchFromRawData(@[touchUp1,touchUp2]);
}


#pragma mark - 捏合
+(void)zoomOut:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(int)duration {
    
    if (duration == 0) {
        duration = 50;
    }
    
    // 计算两个触摸点的中间点
    CGPoint centerPoint = CGPointMake((fromPoint.x + toPoint.x) / 2, (fromPoint.y + toPoint.y) / 2);
    
    // 计算两个触摸点之间的距离
    float distance = sqrt(pow(toPoint.x - fromPoint.x, 2) + pow(toPoint.y - fromPoint.y, 2));
    
    // 根据指定的持续时间和距离，计算出移动操作需要分成的段数
    // 这里取距离除以5和持续时间除以20的较小值作为段数，以保证移动不会太快
    int steps = MIN(distance / 5, duration / 20);
    if (steps == 0) steps = 2; // 防止除以0的情况
    
    
    float stepX = (centerPoint.x - fromPoint.x) / steps; // 从起始点到中心点的移动增量
    float stepY = (centerPoint.y - fromPoint.y) / steps;
    
    // 初始化两个手指的起始点
    CGPoint point1 = fromPoint;
    CGPoint point2 = toPoint;
    
    // 最后一步确保手指保持一定距离
    float finalDistance = 10.0; // 最终距离可以根据需要调整
    float angle = atan2(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x);
    CGPoint finalPoint1 = CGPointMake(centerPoint.x - finalDistance / 2 * cos(angle), centerPoint.y - finalDistance / 2 * sin(angle));
    CGPoint finalPoint2 = CGPointMake(centerPoint.x + finalDistance / 2 * cos(angle), centerPoint.y + finalDistance / 2 * sin(angle));
    
    
    // 创建按下（DOWN）事件
    YKTouch *touch1 = [self generateYKTouch:point1 fingerId:14 touchType:YKTouchTypeDOWN];
    YKTouch *touch2 = [self generateYKTouch:point2 fingerId:15 touchType:YKTouchTypeDOWN];
    performTouchFromRawData(@[touch1, touch2]);
    
    // 逐步移动两根手指到中心点
    for (int i = 0; i < steps; i++) {
        
        if (i + 1 == steps) {
            // 执行到最后一步
            point1 = finalPoint1;
            point2 = finalPoint2;
        } else {
            
            // 判断 point1 是否需要增加或减少以靠近 centerPoint
            if (point1.x < centerPoint.x) {
                point1.x += stepX;
            } else if (point1.x > centerPoint.x) {
                point1.x -= stepX;
            }
            
            if (point1.y < centerPoint.y) {
                point1.y += stepY;
            } else if (point1.y > centerPoint.y) {
                point1.y -= stepY;
            }
            
            // 判断 point2 是否需要增加或减少以靠近 centerPoint
            if (point2.x < centerPoint.x) {
                point2.x += stepX;
            } else if (point2.x > centerPoint.x) {
                point2.x -= stepX;
            }
            
            if (point2.y < centerPoint.y) {
                point2.y += stepY;
            } else if (point2.y > centerPoint.y) {
                point2.y -= stepY;
            }
        }
        
        // 生成新的MOVE事件
        YKTouch *moveTouch1 = [self generateYKTouch:point1 fingerId:14 touchType:YKTouchTypeMOVE];
        YKTouch *moveTouch2 = [self generateYKTouch:point2 fingerId:15 touchType:YKTouchTypeMOVE];
        performTouchFromRawData(@[moveTouch1, moveTouch2]);
        usleep(1000 * duration / steps); // 控制每一步的移动速度
    }
    // 创建抬起（UP）事件
    YKTouch *touchUp1 = [self generateYKTouch:finalPoint1 fingerId:14 touchType:YKTouchTypeUP];
    YKTouch *touchUp2 = [self generateYKTouch:finalPoint2 fingerId:15 touchType:YKTouchTypeUP];
    
    // 执行抬起事件
    performTouchFromRawData(@[touchUp1, touchUp2]);
}

#pragma mark - 获取当前的数量
+(int)getCurrentTouchCount {
    return currentTouchIndex;;
}

#pragma mark - 终止
+(void)clear {
    
    stopTouchMove = YES;
    // 检查是否有需要补发的 UP 事件
    BOOL hasValidEvents = NO;
    for (int i = 0; i < MAX_FINGER_INDEX; i++) {
        if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID) {
            hasValidEvents = YES;
            break;
        }
    }
    
    // 如果没有有效事件，直接返回
    if (!hasValidEvents) {
        return;
    }
    
    AbsoluteTime frameTime = generateTime();
    IOHIDEventRef parent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, frameTime, kIOHIDTransducerTypeHand, 99, 1, 0, 0, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0);
    IOHIDEventSetIntegerValue(parent, 0xb0019, 1);
    IOHIDEventSetIntegerValue(parent, 0x4, 1);
    
    // 遍历 eventsToAppend，查找需要补发的 UP 事件
    for (int i = 0; i < MAX_FINGER_INDEX; i++) {
        if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID) {
            // 补发 UP 事件
            int x = eventsToAppend[i][EVENT_X_INDEX];
            int y = eventsToAppend[i][EVENT_Y_INDEX];
            appendChildEvent(parent, YKTouchTypeUP, i, x, y, frameTime);
            
            // 标记为无效
            eventsToAppend[i][EVENT_VALID_INDEX] = NOT_VALID;
        }
    }
    
    // 发送事件
    IOHIDEventSetIntegerValue(parent, 0xb0007, 0x23);
    IOHIDEventSetIntegerValue(parent, 0xb0008, 0x1);
    IOHIDEventSetIntegerValue(parent, 0xb0009, 0x1);
    postIOHIDEvent(parent);
    
    // 释放主事件
    CFRelease(parent);
}


#pragma mark - 补发Up事件
+(void)forceTouchUpIfNeeded:(int)fingerId {
    
    if (fingerId < 0 || fingerId >= MAX_FINGER_INDEX) {
        return;
    }
    
    if (eventsToAppend[fingerId][EVENT_VALID_INDEX] == VALID) {
        // 补发 UP 事件
        int x = eventsToAppend[fingerId][EVENT_X_INDEX];
        int y = eventsToAppend[fingerId][EVENT_Y_INDEX];
        [self touchUp:CGPointMake(x, y) fingerId:fingerId];
        //[[YKServiceFileLogger sharedInstance] write:[NSString stringWithFormat:@"需要补发%d",fingerId]];
    }
}


#pragma mark - 获取到最后一个fingerId
+(nullable YKTouch *)findYKTouchByFingerId:(int)fingerId {
    
    // 检查指纹 ID 是否在有效范围内
    if (fingerId < 0 || fingerId >= MAX_FINGER_INDEX) {
        return nil; // fingerId 无效
    }
    
    // 根据 fingerId 查找对应的触摸事件
    int eventType = eventsToAppend[fingerId][EVENT_TYPE_INDEX];
    int x = eventsToAppend[fingerId][EVENT_X_INDEX];
    int y = eventsToAppend[fingerId][EVENT_Y_INDEX];
    
    // 直接创建并返回 YKTouch 对象
    CGPoint point = CGPointMake(x, y);
    
    YKTouch *touch = [[YKTouch alloc] init];
    touch.point = point;
    touch.fingerId = fingerId;
    touch.type = eventType;
    return touch;
}


#pragma mark - 获取随机值
+(int)getRandomNumberFrom:(NSInteger)from to:(NSInteger)to {
    return (int)(from + arc4random_uniform((uint32_t)(to - from + 1)));
}



#pragma mark - private static
//============================================================
// 创建Touch IOHIDEventRef
//============================================================
static IOHIDEventRef generateChildEventTouchDown(int index, float x, float y, AbsoluteTime time) {
    
    IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, time, index, 3, 3, x/generateWidth(), y/generateHeight(), 0.0f, 0.0f, 0.0f, 1, 1, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f);
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f);
    return child;
}

static IOHIDEventRef generateChildEventTouchMove(int index, float x, float y, AbsoluteTime time) {
    
    IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, time, index, 3, 4, x/generateWidth(), y/generateHeight(), 0.0f, 0.0f, 0.0f, 1, 1, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f);
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f);
    return child;
}

static IOHIDEventRef generateChildEventTouchUp(int index, float x, float y, AbsoluteTime time)
{
    IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, time, index, 3, 2, x/generateWidth(), y/generateHeight(), 0.0f, 0.0f, 0.0f, 0, 0, 0);
    IOHIDEventSetFloatValue(child, 0xb0014, 0.04f);
    IOHIDEventSetFloatValue(child, 0xb0015, 0.04f);
    return child;
}

static void appendChildEvent(IOHIDEventRef parent, YKTouchType type, int index, float x, float y, AbsoluteTime time)
{
    switch (type)
    {
        case YKTouchTypeDOWN:
        {
            IOHIDEventAppendEvent(parent, generateChildEventTouchDown(index, x, y, time));
        }
            break;
        case YKTouchTypeMOVE:
        {
            IOHIDEventAppendEvent(parent, generateChildEventTouchMove(index, x, y, time));
        }
            break;
        case YKTouchTypeUP:
        {
            IOHIDEventAppendEvent(parent, generateChildEventTouchUp(index, x, y, time));
        }
            break;
        default:
            break;
    }
}

void performTouchFromRawData(NSArray<YKTouch *> *touchs) {
    
    
    AbsoluteTime frameTime = generateTime();
    
    IOHIDEventRef parent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, frameTime, kIOHIDTransducerTypeHand, 99, 1, 0, 0, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0);
    IOHIDEventSetIntegerValue(parent, 0xb0019, 1);
    IOHIDEventSetIntegerValue(parent, 0x4, 1);
    for (YKTouch *touch in touchs) {
        
        appendChildEvent(parent, touch.type, touch.fingerId, touch.point.x, touch.point.y, frameTime);
        switch (touch.type) {
            case YKTouchTypeDOWN: {
                eventsToAppend[touch.fingerId][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                eventsToAppend[touch.fingerId][EVENT_TYPE_INDEX] = YKTouchTypeDOWN;
                eventsToAppend[touch.fingerId][EVENT_X_INDEX] = (int)touch.point.x;
                eventsToAppend[touch.fingerId][EVENT_Y_INDEX] = (int)touch.point.y;
            }
                break;
            case YKTouchTypeMOVE: {
                eventsToAppend[touch.fingerId][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                eventsToAppend[touch.fingerId][EVENT_TYPE_INDEX] = YKTouchTypeMOVE;
                eventsToAppend[touch.fingerId][EVENT_X_INDEX] = (int)touch.point.x;
                eventsToAppend[touch.fingerId][EVENT_Y_INDEX] = (int)touch.point.y;
            }
                break;
            case YKTouchTypeUP: {
                eventsToAppend[touch.fingerId][EVENT_VALID_INDEX] = NOT_VALID;
            }
                break;
            default:
                break;
        }
    }
    
    for (int i = 0; i < MAX_FINGER_INDEX; i++)
    {
        if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID)
        {
            appendChildEvent(parent, eventsToAppend[i][EVENT_TYPE_INDEX], i, eventsToAppend[i][EVENT_X_INDEX], eventsToAppend[i][EVENT_Y_INDEX], frameTime);
        }
        else if (eventsToAppend[i][EVENT_VALID_INDEX] == VALID_AT_NEXT_APPEND)
        {
            eventsToAppend[i][EVENT_VALID_INDEX] = VALID;
        }
    }
    
    IOHIDEventSetIntegerValue(parent, 0xb0007, 0x23);
    IOHIDEventSetIntegerValue(parent, 0xb0008, 0x1);
    IOHIDEventSetIntegerValue(parent, 0xb0009, 0x1);
    postIOHIDEvent(parent);
    CFRelease(parent);
}



static AbsoluteTime generateTime(void) {
    uint64_t abTime = mach_absolute_time();
    AbsoluteTime timeStamp = *(AbsoluteTime *) &abTime;
    return timeStamp;
}

static CGFloat generateWidth(void) {
    return UIScreen.mainScreen.currentMode.size.width;
}

static CGFloat generateHeight(void) {
    return UIScreen.mainScreen.currentMode.size.height;
}

static void postIOHIDEvent(IOHIDEventRef event)
{
    // 1. 创建并维护一个全局唯一的 IOHID 系统客户端
    static IOHIDEventSystemClientRef _ioSystemClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建用于与系统 HID 服务通信的客户端
        _ioSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    });
    IOHIDEventSetSenderID(event, 0x8000000817319372);
    IOHIDEventSystemClientDispatchEvent(_ioSystemClient, event);
}

//============================================================
// 主屏幕键 (Home Button / Menu)(已验证✅)
//============================================================
+(void)menuPress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:NO];
}


+(void)menuDoublePress {
    
    struct timespec doubleDelay = { 0, (long)(multiTapInterval * nanosecondsPerSecond) };
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:NO];
    nanosleep(&doubleDelay, 0);
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Menu isKeyDown:NO];
}


+(void)mutePress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Mute isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Mute isKeyDown:NO];
}

+(void)powerPress {

    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Power isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Power isKeyDown:NO];
}

+(void)volupPress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_VolumeIncrement isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_VolumeIncrement isKeyDown:NO];
}

+(void)voldownPress {
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_VolumeDecrement isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_VolumeDecrement isKeyDown:NO];
}

+(void)snapshotPress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Snapshot isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_Snapshot isKeyDown:NO];
}


+(void)toggleSpotlight {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_ACSearch isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_ACSearch isKeyDown:NO];
}


+(void)displayBrightnessIncrementPress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_DisplayBrightnessIncrement isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_DisplayBrightnessIncrement isKeyDown:NO];
}

+(void)displayBrightnessDecrementPress {
    
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_DisplayBrightnessDecrement isKeyDown:YES];
    [self _sendIOHIDKeyboardEvent:kHIDPage_Consumer usage:kHIDUsage_Csmr_DisplayBrightnessDecrement isKeyDown:NO];
}


+(void)pastePress {
    [YKSimulator keyPressCode:231 action: 1];
    [YKSimulator keyPressCode:25 action: 0];
    [YKSimulator keyPressCode:231 action: 2];
}
@end
#pragma clang diagnostic pop

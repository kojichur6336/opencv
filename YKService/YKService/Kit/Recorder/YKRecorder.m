//
//  YKRecorder.m
//  Created on 2025/10/8
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKRecorder.h"
#import <UIKit/UIKit.h>
#import "YKServiceLogger.h"
#import <IOKit/hid/IOHIDEvent7.h>
#import <IOKit/hid/IOHIDEventSystemClient.h>

@interface YKRecorder()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *eventMap;
@property(nonatomic, assign) IOHIDEventSystemClientRef client;
@property(nonatomic, assign) CFAbsoluteTime fLastEventTime;
@property(nonatomic, strong) NSMutableString *recordCode;

-(void)recordEvent:(IOHIDEventRef)event;
-(int)getDelay;
-(void)getHomeKeyCode:(int)down time:(int)time;
-(void)getTouchCode:(int)x y:(int)y idx:(int)idx type:(int)type time:(int)time;
@end


@implementation YKRecorder

-(instancetype)init {
    self = [super init];
    if (self) {
        _isRuning = false;
        _client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        IOHIDEventSystemClientRegisterEventCallback(_client, recordIOHIDEventCallback, (__bridge void *)(self), NULL);
    }
    return self;
}


#pragma mark - 回调callback
void recordIOHIDEventCallback(void *target, void *refcon, IOHIDEventQueueRef queue, IOHIDEventRef event)
{
    YKRecorder *recorder = (__bridge YKRecorder *)target;
    [recorder recordEvent:event];
}

#pragma mark - 准备开始录制
-(void)prepare {
    
    if (self.isRuning) return;
    _isRuning = YES;
}


#pragma mark - start
-(void)start {
    
    _fLastEventTime = CFAbsoluteTimeGetCurrent();
    IOHIDEventSystemClientScheduleWithRunLoop(_client, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
}

#pragma mark - 停止
-(void)stop:(void (^)(NSString * _Nonnull))callback {
    
    if (!self.client) return;
    
    IOHIDEventSystemClientUnscheduleWithRunLoop(_client, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    if (callback) callback(self.recordCode.copy);
    _recordCode = nil;
    _isRuning = NO;
}


#pragma mark - 录制事件
-(void)recordEvent:(IOHIDEventRef)event {
    
    IOHIDEventType eventType = IOHIDEventGetType(event);
    switch (eventType)
    {
        case kIOHIDEventTypeDigitizer:
        {
            
            CFArrayRef children = IOHIDEventGetChildren(event);
            if (children == 0x0)
                return;
            int time = [self getDelay];
            CFIndex count = CFArrayGetCount(children);
            for (int i=0; i<count; i++)
            {
                IOHIDEventRef childEvent = (IOHIDEventRef)CFArrayGetValueAtIndex(children, i);
                IOHIDFloat x = IOHIDEventGetFloatValue(childEvent, (IOHIDEventField)kIOHIDEventFieldDigitizerX);
                IOHIDFloat y = IOHIDEventGetFloatValue(childEvent, (IOHIDEventField)kIOHIDEventFieldDigitizerY);
                int ix = UIScreen.mainScreen.currentMode.size.width * x;
                int iy = UIScreen.mainScreen.currentMode.size.height * y;
                
                int mask  = IOHIDEventGetIntegerValue(childEvent, kIOHIDEventFieldDigitizerEventMask);
                int index = IOHIDEventGetIntegerValue(childEvent, kIOHIDEventFieldDigitizerIndex);
                int touch = IOHIDEventGetIntegerValue(childEvent, kIOHIDEventFieldDigitizerTouch);
                int range = IOHIDEventGetIntegerValue(childEvent, kIOHIDEventFieldDigitizerRange);
                
                int type = -1; // 0:move, 1:down, 2:up, -1:unkown
                while(true)
                {
                    if(mask & kIOHIDDigitizerEventAttribute && mask & kIOHIDDigitizerEventTouch) {
                        type = touch == 0? 2 : -1;
                    }
                    if( mask & kIOHIDDigitizerEventAttribute && mask & kIOHIDDigitizerEventRange) {
                        type = range == 0? 2 : -1;
                    }
                    
                    if( touch == 0 || range == 0){
                        type = 2;
                    }
                    
                    if(type == 2)
                        break;
                    
                    if(mask & kIOHIDDigitizerEventPosition) {
                        type = 0;
                    } else {
                        type = 1;
                    }
                    break;
                }
                [self getTouchCode:ix y:iy idx:index type:type time: i == 0? time : 0];
            }
            break;
        }
        case kIOHIDEventTypeKeyboard:
        {
            int time = [self getDelay];
            int usage = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardUsage);
            int down  = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardDown);
            if (usage == 64)
            {
                [self getHomeKeyCode:down time:time];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - 获取延时
-(int)getDelay {
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    int delay = (now - _fLastEventTime) * 1000;
    _fLastEventTime = now;
    return delay;
}

#pragma mark - 获取点击编码
-(void)getTouchCode:(int)x y:(int)y idx:(int)idx type:(int)type time:(int)time {
    
    NSNumber *index = @(idx);
    NSNumber *value = @(type);
    
    switch (type) {
        case 0:
            // TouchMoveEvent
            if (self.eventMap[index]) {
                [self.recordCode appendFormat:@"YKTouchMoveEvent %d,%d,%d,%d\n", time, idx, x, y];
                LOGI(@"YKTouchMoveEvent");
            }
            break;
        case 1:
            // Delay and TouchDownEvent
            if (!self.eventMap[index]) {
                [self.recordCode appendFormat:@"YKTouchDownEvent %d,%d,%d,%d\n", time, idx, x, y];
                self.eventMap[index] = value;
                LOGI(@"YKTouchDownEvent");
            }
            break;
        case 2:
            // TouchUpEvent
            if (self.eventMap[index]) {
                [self.eventMap removeObjectForKey:index];
                [self.recordCode appendFormat:@"YKTouchUpEvent %d,%d,%d,%d\n", time, idx, x, y];
                LOGI(@"YKTouchUpEvent");
            }
            break;
            
        default:
            break;
    }
}



#pragma mark - 获取键盘KeyCode
-(void)getHomeKeyCode:(int)down time:(int)time {
    
    NSMutableString *code = [NSMutableString string];
    if (down) {
        [code appendFormat:@"Delay %d\n", time];
        [code appendString:@"KeyDown \"Home\"\n"];
    } else {
        [code appendFormat:@"Delay %d\n", time];
        [code appendString:@"KeyUp \"Home\"\n"];
    }
    [self.recordCode appendString:code];
}

#pragma mark - lazy
-(NSMutableDictionary<NSNumber *,NSNumber *> *)eventMap
{
    if (!_eventMap) {
        _eventMap = [NSMutableDictionary dictionary];
    }
    return _eventMap;
}
-(NSMutableString *)recordCode
{
    if (!_recordCode) {
        _recordCode = [NSMutableString string];
    }
    return _recordCode;
}
@end


/*
 
tap {
 Range Touch                        range=1,touch=1,mask=3
 Range Touch                        range=0,touch=0,mask=3
 
 Range Touch                        range=1,touch=1,mask=3
 Touch                              range=1,touch=0,mask=2
 Range                              range=0,touch=0,mask=1
 
 Range Touch Attribute FromEdgeTip  range=1,touch=1,mask=2115
 Attribute                          range=1,touch=1,mask=64
 Range Touch                        range=0,touch=0,mask=3
 
 Range Touch Attribute FromEdgeTip  range=1,touch=1,mask=2115
 Touch FromEdgeTip                  range=1,touch=0,mask=2050
 Range FromEdgeTip                  range=0,touch=0,mask=2049
 
 Range Touch Attribute FromEdgeTip  range=1,touch=1,mask=2115
 Range Touch FromEdgeTip            range=0,touch=0,mask=2051
 }
 
swipe {
 Range Touch                        range=1,touch=1,mask=3
 Position                           range=1,touch=1,mask=4
 Position                           range=1,touch=1,mask=4
 Position                           range=1,touch=1,mask=4
 Range Touch                        range=0,touch=0,mask=3
 
 Range Attribute FromEdgeTip        range=1,touch=0,mask=2113
 Touch FromEdgeTip                  range=1,touch=1,mask=2050
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Range Touch FromEdgeTip            range=0,touch=0,mask=2051
 
 Range Touch Attribute FromEdgeTip  range=1,touch=1,mask=2115
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Position FromEdgeTip               range=1,touch=1,mask=2052
 Range Touch FromEdgeTip            range=0,touch=0,mask=2051

 iOS6
 Range Touch                        range=1,touch=1,mask=3
 Position                           range=1,touch=1,mask=4
 Position                           range=1,touch=1,mask=4
 Position                           range=1,touch=1,mask=4
 Touch                              range=1,touch=0,mask=2
 Range                              range=0,touch=0,mask=1
 
 Touch Identity                     range=1,touch=1,mask=34
 Position                           range=1,touch=1,mask=4
 Position                           range=1,touch=1,mask=4
 Range Touch                        range=0,touch=0,mask=3
 
 多指的时候会有stay状态，mask=0,range=1,touch=1
 }
 
 multiTouch {
    {Range                          range=1,touch=0,mask=1,index=9}
    {Touch Position                 range=1,touch=1,mask=6,index=9}
    {Position                       range=1,touch=1,mask=4,index=9}
    {
        Touch Identity              range=1,touch=1,mask=34,index=8
        Position Identity           range=1,touch=1,mask=36,index=9
    }
 }
 
 总结：
 TouchDown:
    Range:                              range=1,touch=0,mask=1
    Range|Touch:                        range=1,touch=1,mask=3
    Touch|Identity:                     range=1,touch=1,mask=34
    iOS8+
    Range|Attribute|FromEdgeTip:        range=1,touch=0,mask=2113
    Range|Touch|Attribute|FromEdgeTip:  range=1,touch=1,mask=2115
 
 TouchMove:
    Position:                           range=1,touch=1,mask=4
    Touch:                              range=1,touch=0,mask=2
    Attribute:                          range=1,touch=1,mask=64
    Touch|FromEdgeTip:                  range=1,touch=0,mask=2050
    Position|FromEdgeTip:               range=1,touch=1,mask=2052
    Position|Touch:                     range=1,touch=1,mask=6
    Position|Identity:                  range=1,touch=1,mask=36
    Stay:                               range=1,touch=1,mask=0
 
 TouchUp:
    Range:                              range=0,touch=0,mask=1
    Range|Touch:                        range=0,touch=0,mask=3
    Range|FromEdgeTip:                  range=0,touch=0,mask=2049
    Range|Touch|FromEdgeTip:            range=0,touch=0,mask=2051
 
 */

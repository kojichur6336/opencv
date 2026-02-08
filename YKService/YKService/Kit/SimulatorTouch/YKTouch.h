//
//  YKTouch.h
//  YKSimulatorTouch
//
//  Created by xiaobin liu on 2024/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - Touch类型
typedef NS_ENUM(NSUInteger, YKTouchType) {
    YKTouchTypeMOVE,
    YKTouchTypeDOWN,
    YKTouchTypeUP,
};


/// MARK - 点击
@interface YKTouch : NSObject
@property(nonatomic, assign) YKTouchType type;
@property(nonatomic, assign) int fingerId;
@property(nonatomic, assign) CGPoint point;

@end

NS_ASSUME_NONNULL_END

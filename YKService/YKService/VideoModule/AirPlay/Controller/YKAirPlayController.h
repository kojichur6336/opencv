//
//  YKAirPlayController.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/18.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKAirPlayController;
@protocol YKAirPlayControllerDelegate <NSObject>

-(void)airPlayController:(YKAirPlayController *)airPlayController data:(NSData *)data;
@end


/// MARK - AirPlay 控制器
@interface YKAirPlayController : NSObject
@property(nonatomic, copy, readonly) NSString *airPlayName;//airPlay名称


/// 初始化
/// - Parameters:
///   - error: 错误原因
///   - delegate: 委托
-(instancetype)initWithError:(NSError **)error delegate:(id<YKAirPlayControllerDelegate>) delegate;


/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

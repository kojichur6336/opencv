//
//  YKKeyMap.h
//  YKSimulatorTouch
//
//  Created by xiaobin liu on 2024/6/14.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/// MARK - 键盘映射
@interface YKKeyMap : NSObject

/// 获取编码
/// - Parameter key: <#key description#>
+(int)getCode:(NSString *)key;


/// 获取自定义编码的键盘输入值
+(NSDictionary *)keyboardKeyMap;


/// 中文映射
+(NSDictionary *)chineseKeyMap;
@end

NS_ASSUME_NONNULL_END

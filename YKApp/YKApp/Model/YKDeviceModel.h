//
//  YKDeviceModel.h
//  YKApp
//
//  Created by liuxiaobin on 2025/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 设备实体
@interface YKDeviceModel : NSObject
@property(nonatomic, strong) NSArray *connected;//连接数组
@property(nonatomic, copy) NSString *deviceID;//设备信息
@end

NS_ASSUME_NONNULL_END

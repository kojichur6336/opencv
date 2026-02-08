//
//  YKServiceModel.h
//  YKService
//
//  Created by liuxiaobin on 2025/12/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 远控服务实体
@interface YKServiceModel : NSObject<NSSecureCoding>
@property(nonatomic, assign) BOOL isServiceEnabled;//是否启用了服务
@property(nonatomic, assign) int autoReconnectInterval;//自动重连间隔时间

/// 从本地加载配置
+(instancetype)loadFromDisk;

/// 保存当前配置到本地
-(void)saveToDisk;
@end

NS_ASSUME_NONNULL_END

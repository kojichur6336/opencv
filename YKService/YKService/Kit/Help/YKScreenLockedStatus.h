//
//  YKScreenLockedStatus.h
//  Created on 2025/9/26
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YKScreenLockedStatusDelegate <NSObject>

/// 屏幕状态改变
/// - Parameter status: 状态
-(void)screenLockedStatusChanged:(BOOL)status;

@end


/// MARK - 屏幕锁屏状态
@interface YKScreenLockedStatus : NSObject
@property(nonatomic, weak) id<YKScreenLockedStatusDelegate> delegate;


/// 主动获取锁屏状态
-(BOOL)fetchCurrentLockState;
@end

NS_ASSUME_NONNULL_END

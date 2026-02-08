//
//  YKListeningRingerState.h
//  Created on 2026/1/24
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKListeningRingerState;
@protocol YKListeningRingerStateDelegate <NSObject>

/// 静音状态回调
/// - Parameters:
///   - manager: 实例本身
///   - isMuted: YES: 当前为静音模式, NO: 当前为响铃模式
-(void)listeningRingerState:(YKListeningRingerState *)manager didUpdateMuteState:(BOOL)isMuted;

@end


/// MARK - 监听静音状态
@interface YKListeningRingerState : NSObject

/// 代理对象
@property (nonatomic, weak) id<YKListeningRingerStateDelegate> delegate;

/// 当前是否为静音状态 (实时读取)
@property (nonatomic, readonly) BOOL isMuted;

@end

NS_ASSUME_NONNULL_END

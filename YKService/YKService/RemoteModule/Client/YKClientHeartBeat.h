//
//  YKClientHeartBeat.h
//  Created on 2025/9/20
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YKClientHeartBeat;
@protocol YKClientHeartBeatDelegate <NSObject>

/// 心跳回调函数
/// - Parameter sender: 触发心跳的对象
-(void)didReceiveHeartBeat:(YKClientHeartBeat *)sender;

@end

/// MARK - 心跳
@interface YKClientHeartBeat : NSObject

/// 初始化
/// - Parameters:
///   - delegate: 回调
-(instancetype)initWithDelegate:(id<YKClientHeartBeatDelegate>)delegate;

/// 开始
-(void)start;

/// 停止
-(void)stop;
@end

NS_ASSUME_NONNULL_END

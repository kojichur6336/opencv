//
//  YKRecorder.h
//  Created on 2025/10/8
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 录制
@interface YKRecorder : NSObject
@property(nonatomic, copy) NSString *identifier;//连接唯一标识
@property(nonatomic, copy) NSString *deviceName;//当前设备名称
@property(nonatomic, assign, readonly) BOOL isRuning;// 是否运行中


/// 准备开始录制
-(void)prepare;

/// 开始
-(void)start;

/// 停止录制
/// - Parameter callback: 内容
-(void)stop:(void(^)(NSString *content))callback;
@end

NS_ASSUME_NONNULL_END

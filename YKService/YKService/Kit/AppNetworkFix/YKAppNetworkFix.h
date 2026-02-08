//
//  YKAppNetworkFix.h
//  Created on 2026/1/31
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 网络修复
@interface YKAppNetworkFix : NSObject

/// App网络修复
/// - Parameter bid: 包名
+(void)networkFix:(NSString *)bundleIdentifier;
@end

NS_ASSUME_NONNULL_END

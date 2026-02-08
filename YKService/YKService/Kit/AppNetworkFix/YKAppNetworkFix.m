//
//  YKAppNetworkFix.m
//  Created on 2026/1/31
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "YKServiceLogger.h"
#import "YKAppNetworkFix.h"
#import <CoreServices/CoreServices.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


void* _CTServerConnectionCreate(CFAllocatorRef, void *, void *);
int64_t _CTServerConnectionSetCellularUsagePolicy(CFTypeRef* ct, NSString* identifier, NSDictionary* policies);

@implementation YKAppNetworkFix

#pragma mark - App网络修复
+(void)networkFix:(NSString *)bundleIdentifier {
    
    //com.apple.CommCenter.fine-grained  data-allowed-write 修复网络权限
    _CTServerConnectionSetCellularUsagePolicy(
        _CTServerConnectionCreate(kCFAllocatorDefault, NULL, NULL),
        bundleIdentifier,
        @{
            @"kCTCellularDataUsagePolicy" : @"kCTCellularDataUsagePolicyAlwaysAllow",
            @"kCTWiFiDataUsagePolicy" : @"kCTCellularDataUsagePolicyAlwaysAllow"
        }
    );
}
@end


#pragma clang diagnostic pop

//
//  YKServiceEncrypt.h
//  YKService
//
//  Created by liuxiaobin on 2025/12/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YKServiceEncrypt                    Ad8be5f23s17d7af456a71dc6c63d4538fj
#define yk_aesEncrypt                       B4f622x13c3ca30cb1060ed64728b0ebee3
#define yk_aesDecrypt                       C5c384d8xla31ec20286c8f5aa9b1bfc448


/// MARK - 加密类
@interface YKServiceEncrypt : NSObject

/// ase加密
/// - Parameter data: 数据
+(NSData *)yk_aesEncrypt:(NSData *)data;

/// aes解密
/// - Parameter data: 数据
+(NSData *)yk_aesDecrypt:(NSData *)data;
@end

NS_ASSUME_NONNULL_END

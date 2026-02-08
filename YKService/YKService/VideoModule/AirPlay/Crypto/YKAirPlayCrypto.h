//
//  YKAirPlayCrypto.h
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK -  AirPlay 加解密
@interface YKAirPlayCrypto : NSObject


/// 生成pairSetup 公钥
-(NSData *)pairSetupPublic;


/// 验签pairVerify 步骤1
-(NSData *)pairVerifySign1:(NSData *)data;


/// 验签pairVerify 步骤2
-(BOOL)pairVerifySign2:(NSData *)data;


/// 获取SETUP1  AES Key密钥
/// - Parameters:
///   - datFairPlay: datFairPlay
///   - ekey: ekey
-(void)SETUP1:(NSData *)datFairPlay ekey:(NSData *)ekey;


/// 解密镜像
/// - Parameter streamConnectionID: 流的连接ID
-(BOOL)mirrorDecode:(uint64_t)streamConnectionID;


/// 镜像SPSPPS数据解密
/// - Parameter data: 数据
-(NSData *)mirrorSPSPPSDataDecode:(NSData *)data;


/// 解密镜像数据
/// - Parameter data: 数据
-(NSData *)mirrorDataDecode:(NSData *)data;
@end

NS_ASSUME_NONNULL_END

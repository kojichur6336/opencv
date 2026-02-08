//
//  YKAirPlayController.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/18.
//  https://openairplay.github.io/airplay-spec/service_discovery.html
//  https://github.com/apple-oss-distributions/mDNSResponder
//  https://developer.apple.com/documentation/dnssd?language=objc



#import <UIKit/UIKit.h>
#import "YKServiceLogger.h"
#import "YKAirPlayMirror.h"
#import "YKAirPlayCrypto.h"
#import "YKAirPlayController.h"
#import "YKAirPlayRTSPServer.h"
#import "YKAirPlayServiceRegister.h"

#import "YKAirPlayAudio.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface YKAirPlayController()
@property(nonatomic, strong) YKAirPlayServiceRegister *serviceRegister;//服务注册
@property(nonatomic, strong) YKAirPlayRTSPServer *rtspServer;//RTSP服务
@property(nonatomic, strong) YKAirPlayMirror *airPlayMirror;//AirPlay镜像控制器
@property(nonatomic, strong) YKAirPlayCrypto *airPlayCrypto;//airPlay加密
@property(nonatomic, assign) int rtspPort;//RTSP端口
@property(nonatomic, assign) int mirrorPort;//镜像端口
@property(nonatomic, assign) BOOL isRecording;//是否录制
@property(nonatomic, strong) NSFileHandle *fileHandle;//文件操作
@property(nonatomic, copy) NSString *recordFilePath;//路径本地的路径
@property(nonatomic, weak) id<YKAirPlayControllerDelegate> delegate;//委托

@property(nonatomic, strong) YKAirPlayAudio *airPlayAudio;//音频播放
@property(nonatomic, strong) NSDictionary * audioPort;//音频端口
@end


@interface YKAirPlayController(airPlayRTSPServerDelegate) <YKAirPlayRTSPServerDelegate>
@end

@interface YKAirPlayController(airPlayMirrorDelegate) <YKAirPlayMirrorDelegate>
@end


@implementation YKAirPlayController

-(instancetype)initWithError:(NSError *__autoreleasing  _Nullable *)error delegate:(id<YKAirPlayControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        
        _delegate = delegate;
        _airPlayCrypto = [[YKAirPlayCrypto alloc] init];
        _airPlayName = [NSString stringWithFormat:@"%@(YK)",UIDevice.currentDevice.name];
        
        _rtspServer = [[YKAirPlayRTSPServer alloc] initWithDelegate:self];
        
        
        _airPlayAudio = [[YKAirPlayAudio alloc] init];
        _audioPort = [_airPlayAudio startWithError:error];
        LOGI(@"音频端口是%d",_audioPort);
        
        int port = [_rtspServer startWithError:error];
        if (!*error) {
            LOGI(@"创建AirPlayRTSPServer服务成功Port = %d", port);
            _rtspPort = port;
            
            _serviceRegister = [[YKAirPlayServiceRegister alloc] initWithPort:_rtspPort];
            BOOL result = [_serviceRegister serviceRegister:_airPlayName];
            if (result) {
                LOGI(@"创建AirPlayServiceRegister服务成功");
                
                _airPlayMirror = [[YKAirPlayMirror alloc] initWithDelegate:self];
                int airPlayMirrorPort = [_airPlayMirror startWithError:error];
                if (!*error)
                {
                    LOGI(@"创建AirPlayMirror服务成功");
                    _mirrorPort = airPlayMirrorPort;
                    
                } else {
                    LOGI(@"创建AirPlayMirror服务失败");
                }
            } else {
                
                LOGI(@"创建AirPlayServiceRegister服务失败");
            }
        } else {
            LOGI(@"创建AirPlayRTSPServer服务失败");
        }
        
        _isRecording = NO;
#if LogMode == 1
        if (_isRecording) {
            [self startLocalRecording];
        }
#endif
        
    }
    return self;
}


#pragma mark - 停止
-(void)stop {
    
    if (_rtspServer) {
        [_rtspServer stop];
    }
    
    if (_airPlayMirror) {
        [_airPlayMirror stop];
    }
    
    if (_serviceRegister) {
        [_serviceRegister deallocate];
    }
}


#pragma mark - 开始本地录制
-(void)startLocalRecording {
    
    // 录制文件保存路径
    NSString *fileName = @"output.h264";
    NSString *path = [NSString stringWithFormat:@"/tmp/%@",fileName];
    
    // 删除已有文件
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    // 创建空文件
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    
    self.recordFilePath = path;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    LOGI(@"开始本地录制: %@", path);
}

#pragma mark - 停止本地录制
-(void)stopLocalRecording {
    
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    LOGI(@"录制已停止，文件保存在: %@", self.recordFilePath);
}
@end



//============================================================
// RTSP 回调
//============================================================
@implementation YKAirPlayController(airPlayRTSPServerDelegate)
-(NSData *)airPlayRTSPServerGetPairSetupPublicKey {
    
    return [_airPlayCrypto pairSetupPublic];
}

-(NSData *)airPlayRTSPServer:(YKAirPlayRTSPServer *)service pairVerifySign1:(NSData *)pairVerifySign1 {
    return [_airPlayCrypto pairVerifySign1:pairVerifySign1];
}

-(BOOL)airPlayRTSPServer:(YKAirPlayRTSPServer *)service pairVerifySign2:(NSData *)pairVerifySign2 {
    return [_airPlayCrypto pairVerifySign2:pairVerifySign2];
}

-(void)airPlayRTSPServer:(YKAirPlayRTSPServer *)service appleFairPlayDRM:(NSData *)appleFairPlayDRM ekey:(NSData *)ekey {
    
    [_airPlayCrypto SETUP1:appleFairPlayDRM ekey:ekey];
}

-(int)airPlayRTSPServerGetMirrorPort {
    return _mirrorPort;
}

-(NSDictionary *)airPlayRTSPServerGetAudioPort {
    return _audioPort;
}

-(BOOL)airPlayRTSPServer:(YKAirPlayRTSPServer *)service streamConnectionID:(uint64_t)streamConnectionID {
    BOOL result = [_airPlayCrypto mirrorDecode:streamConnectionID];
    if (result) {
        return YES;
    } else {
        return NO;
    }
}

-(void)airPlayRTSPServerStop:(YKAirPlayRTSPServer *)service {
    [_airPlayMirror stop];
#if LogMode == 1
    if (self.isRecording) {
        [self stopLocalRecording];
    }
#endif
}
@end


//============================================================
// 屏幕镜像数据 回调
//============================================================
@implementation YKAirPlayController(airPlayMirrorDelegate)

-(void)airPlayMirror:(YKAirPlayMirror *)airPlayMirror nPayloadType:(int)nPayloadType data:(NSData *)data
{
    if (nPayloadType == 0)
    {
        NSData *result = [_airPlayCrypto mirrorDataDecode:data];
        [_delegate airPlayController:self data:result];
        
#if LogMode == 1
        // 本地录制
        if (self.isRecording && self.fileHandle) {
            [self.fileHandle writeData:result];
        }
#endif
        //LOGI(@"加密的 %@", result);
    } else if (nPayloadType == 1) {
        
        //如果类型为1 一定
        NSData *result = [_airPlayCrypto mirrorSPSPPSDataDecode:data];
        [_delegate airPlayController:self data:result];
        
        
#if LogMode == 1
        // 本地录制
        if (self.isRecording && self.fileHandle) {
            [self.fileHandle writeData:result];
        }
#endif
    } else {
        //LOGI(@"其他数据都不处理");
    }
}
@end


#pragma clang diagnostic pop

//
//  YKScreenBufferCore.m
//  Created on 2025/9/14
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "YKServiceTool.h"
#import <IOKit/IOTypes.h>
#import "YKServiceShell.h"
#import "YKServiceLogger.h"
#import "YKScreenCapturer.h"
#import "YKServiceIOSurface.h"
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>


@interface YKScreenCapturer()
@property(nonatomic, assign) YKVideoQuality type;//清晰类型
@property(nonatomic, readonly) dispatch_queue_t encodeQueue;//编码队列
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) NSInteger preferredFramesPerSecond;//1秒几帧
@property(nonatomic, assign) VTCompressionSessionRef portraitSessionRef;  // 竖屏编码器
@property(nonatomic, assign) VTCompressionSessionRef landscapeSessionRef; // 横屏编码器
@property(nonatomic, assign) BOOL isPortraitSessionActive;  // 当前是否激活竖屏编码器
@property(nonatomic, assign) int64_t frameID;//帧ID
@property(nonatomic, assign) BOOL useH265;//是否使用H265
@property(nonatomic, assign) int frameRate;//帧率 单位为fps
@property(nonatomic, assign) int maxKeyFrameInterval;//最大I帧间隔，单位为秒
@property(nonatomic, assign) BOOL allowFrameReordering;// 是否允许产生B帧 缺省为NO
@property(nonatomic, strong) NSFileHandle *fileHandle;//文件操作
@property(nonatomic, copy) NSString *recordFilePath;//路径本地的路径
@property(nonatomic, assign) BOOL isRecording;//是否录制
@property(nonatomic, assign) UIInterfaceOrientation orientation;//屏幕方向
@property(nonatomic, assign) BOOL isIFrame;//是否I帧
@property(nonatomic, assign) int iFrameCount;//I帧连续几次,3次以后改为NO, 为什么需要这个，主要是因为屏幕方向更改的时候用
@property(nonatomic, assign) CGFloat targetFPS; // 你的目标FPS，例如 0.2, 1, 5, 30
@property(nonatomic, assign) NSTimeInterval lastExecuteTime; // 记录上次执行时间
@property(nonatomic, assign) CGSize portraitResolution;//竖屏大小
@end

@implementation YKScreenCapturer

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        NSString *label = [NSString stringWithFormat:@"com.sky.videoEncode.queue"];
        _encodeQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
        _preferredFramesPerSecond = 30;//每秒钟会调用约 30 次
        _type = YKVideoQualityMedium;
        _frameRate = 30;
        _maxKeyFrameInterval = 30;
        _allowFrameReordering = NO;
        //_useH265 = [self isHEVC];
        _useH265 = NO;
        _orientation = UIInterfaceOrientationPortrait;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
        _displayLink.preferredFramesPerSecond = _preferredFramesPerSecond;
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        _isRecording = NO;
    }
    return self;
}


#pragma mark - 开始
-(void)startWithQuality:(YKVideoQuality)type videoWidth:(int)width videoHeight:(int)height fps:(float)fps completion:(void (^)(void))completion
{
    self.targetFPS = fps;
    self.type = type;
    
    dispatch_async(self.encodeQueue, ^{
        
        if (self.isRecording) {
            [self startLocalRecording];
        }
        
        if (fps <= 1) {
            //如果FPS小于等于1秒的话, 必须设置这三个都为1.这样子每帧都是I帧，不然PC端会糊
            self.preferredFramesPerSecond = 1;
            self.frameRate = 1;
            self.maxKeyFrameInterval = 1;
        } else {
            self.frameRate = fps;
            self.maxKeyFrameInterval = fps;
            self.preferredFramesPerSecond = fps;
        }
        
        // 如果 宽度 > 屏幕宽 或者 高度 > 屏幕高，则强制降级为屏幕原生分辨率
        int temWitdh = width;
        int temHeight = height;
        if (width > [UIScreen mainScreen].nativeBounds.size.width || height > [UIScreen mainScreen].nativeBounds.size.height) {
            temWitdh = [UIScreen mainScreen].nativeBounds.size.width;
            temHeight = [UIScreen mainScreen].nativeBounds.size.height;
        }
        
        self.portraitResolution = CGSizeMake(temWitdh, temHeight);
        CGSize landscapeResolution = CGSizeMake(temHeight, temWitdh);
        
        
        // 创建竖屏编码器
        YYCreateCompressionSession(&self->_portraitSessionRef,
                                   self.portraitResolution,
                                   self.useH265,
                                   self.frameRate,
                                   self.maxKeyFrameInterval,
                                   self.type,
                                   encodeOutputDataCallback,
                                   (__bridge void *)self);
        
        // 创建横屏编码器
        YYCreateCompressionSession(&self->_landscapeSessionRef,
                                   landscapeResolution,
                                   self.useH265,
                                   self.frameRate,
                                   self.maxKeyFrameInterval,
                                   self.type,
                                   encodeOutputDataCallback,
                                   (__bridge void *)self);
        
        if (self.orientation == UIInterfaceOrientationPortrait || self.orientation == UIInterfaceOrientationPortraitUpsideDown) {
            self.isPortraitSessionActive = YES;
        } else {
            self.isPortraitSessionActive = NO;
        }
        
        self.iFrameCount = 0;
        self.isIFrame = YES;
        self.lastExecuteTime = 0;
        if (self.displayLink.paused)
        {
            self.displayLink.preferredFramesPerSecond = self.preferredFramesPerSecond;
            self.displayLink.paused = NO;
        }
        completion();
    });
}


#pragma mark - 停止
-(void)stopWithCompletion:(void (^)(void))completion {
    
    self.displayLink.paused = YES;
    
    dispatch_async(self.encodeQueue, ^{
        
        if (self.isRecording) {
            [self stopLocalRecording];
        }
        
        if (self.portraitSessionRef) {
            
            VTCompressionSessionInvalidate(self.portraitSessionRef);
            CFRelease(self.portraitSessionRef);
            self.portraitSessionRef = NULL;
        }
        
        if (self.landscapeSessionRef) {
            
            VTCompressionSessionInvalidate(self.landscapeSessionRef);
            CFRelease(self.landscapeSessionRef);
            self.landscapeSessionRef = NULL;
        }
        completion();
    });
}

#pragma mark - 更改屏幕方向
-(void)updateOrientation:(UIInterfaceOrientation)newOrientation
{
    self.isIFrame = YES;
    self.orientation = newOrientation;
    if (newOrientation == UIInterfaceOrientationPortrait || newOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.isPortraitSessionActive = YES;
    } else {
        self.isPortraitSessionActive = NO;
    }
}

#pragma mark - 是否支持H265
-(BOOL)isHEVC
{
    // 1️⃣ 获取设备标识符，比如 "iPhone10,1"
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceString = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    
    // 2️⃣ 判断是否 iPhone
    if (![deviceString hasPrefix:@"iPhone"]) {
        return NO; // 只针对 iPhone 判断
    }
    
    // 3️⃣ 解析型号数字
    NSArray<NSString *> *parts = [deviceString componentsSeparatedByString:@","];
    if (parts.count < 1) return NO;
    
    NSString *prefix = [parts.firstObject stringByReplacingOccurrencesOfString:@"iPhone" withString:@""];
    NSInteger major = [prefix integerValue];
    
    // iPhoneXS 起支持 H265 硬件编码（即 A11 芯片起）
    if (major >= 11) { // iPhone11,2
        return YES;
    }
    
    return NO;
}


#pragma mark - 开始本地录制
-(void)startLocalRecording {
    
    // 录制文件保存路径
    NSString *randomString = [[NSUUID UUID] UUIDString];
    NSString *fileName = self.useH265
    ? [NSString stringWithFormat:@"%@_output.hevc", randomString]
    : [NSString stringWithFormat:@"%@_output.h264", randomString];
    NSString *path = [NSString stringWithFormat:@"/tmp/%@",fileName];
    
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

#pragma mark - handleDisplayLink
-(void)handleDisplayLink:(CADisplayLink *)displayLink {
    
    if (_targetFPS > 1.0) {
        [self updateHighFrequencyFrame];
        return;
    }
    
    // 1. 如果 FPS < 1 (例如 0.2)，我们需要手动计算时间差
    NSTimeInterval currentTime = displayLink.timestamp;
    
    // 计算目标间隔，例如 0.2 FPS -> 间隔 5.0 秒
    NSTimeInterval targetInterval = 1.0 / _targetFPS;
    
    // 只有当 (当前时间 - 上次执行时间) 大于等于 目标间隔 时才执行
    if (currentTime - _lastExecuteTime >= targetInterval) {
        _lastExecuteTime = currentTime;
        [self updateLowFrequencyFrame];
    }
}

#pragma mark - 低频更新 (低功耗/监控模式)
-(void)updateLowFrequencyFrame {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_async(self.encodeQueue, ^{
        
        @autoreleasepool {
            
            if (!self.portraitSessionRef || !self.landscapeSessionRef) {
                LOGI(@"已经取消了音视频对象");
                return;
            }
            
            CVPixelBufferRef pixelBuffer = YKCreateResizedRotatedPixelBuffer(self.orientation, self.portraitResolution);
            
            if (pixelBuffer) {
                
                for (int i = 0; i < 3; i++)
                {
                    CMTime presentationTimeStamp = CMTimeMake(self.frameID++, self.frameRate);
                    VTEncodeInfoFlags flags;
                    NSMutableDictionary *frameProperties = [NSMutableDictionary dictionary];
                    if (i == 0) {
                        frameProperties[(id)kVTEncodeFrameOptionKey_ForceKeyFrame] = @(YES);
                    } else {
                        frameProperties = NULL;
                    }
                    
                    OSStatus statusCode = VTCompressionSessionEncodeFrame(self.isPortraitSessionActive ? self.portraitSessionRef : self.landscapeSessionRef,
                                                                          pixelBuffer,
                                                                          presentationTimeStamp,
                                                                          kCMTimeInvalid,
                                                                          (__bridge CFDictionaryRef)frameProperties,
                                                                          NULL,
                                                                          &flags);
                    if (statusCode != noErr)
                    {
                        if (statusCode == -12902) {
                            
                            LOGI(@"mediaserverd 出现了-12902");
                            [self stopWithCompletion:^{
                                [YKServiceShell simple:@"killall -9 mediaserverd > /dev/null"];
                            }];
                        } else {
                            [self stopWithCompletion:^{
                                LOGI(@"状态码是多少%d", statusCode);
                            }];
                        }
                    }
                }
                CVPixelBufferRelease(pixelBuffer);
                pixelBuffer = NULL;
            }
        }
#pragma clang diagnostic pop
    });
}


#pragma mark - 高频更新 (视频流)
-(void)updateHighFrequencyFrame {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_async(self.encodeQueue, ^{
        
        @autoreleasepool {
            
            if (!self.portraitSessionRef || !self.landscapeSessionRef) {
                LOGI(@"已经取消了音视频对象");
                return;
            }
            
            CVPixelBufferRef pixelBuffer = YKCreateResizedRotatedPixelBuffer(self.orientation, self.portraitResolution);
            
            if (pixelBuffer) {
                
                CMTime presentationTimeStamp = CMTimeMake(self.frameID++, self.frameRate);
                VTEncodeInfoFlags flags;
                
                
                NSMutableDictionary *frameProperties = [NSMutableDictionary dictionary];
                if (self.isIFrame) {
                    // 准备 frameProperties，强制该帧为 I 帧
                    frameProperties[(id)kVTEncodeFrameOptionKey_ForceKeyFrame] = @(self.isIFrame);
                } else {
                    frameProperties = NULL;
                }
                
                OSStatus statusCode = VTCompressionSessionEncodeFrame(self.isPortraitSessionActive ? self.portraitSessionRef : self.landscapeSessionRef,
                                                                      pixelBuffer,
                                                                      presentationTimeStamp,
                                                                      kCMTimeInvalid,
                                                                      (__bridge CFDictionaryRef)frameProperties,
                                                                      NULL,
                                                                      &flags);
                if (statusCode != noErr)
                {
                    if (statusCode == -12902) {
                        
                        LOGI(@"mediaserverd 出现了-12902");
                        [self stopWithCompletion:^{
                            [YKServiceShell simple:@"killall -9 mediaserverd > /dev/null"];
                        }];
                    } else {
                        [self stopWithCompletion:^{
                            LOGI(@"状态码是多少%d", statusCode);
                        }];
                    }
                }
                if (self.isIFrame) {
                    self.iFrameCount ++;
                    if (self.iFrameCount >= 3) {
                        self.iFrameCount = 0;
                        self.isIFrame = NO;
                    }
                }
                CVPixelBufferRelease(pixelBuffer);
                pixelBuffer = NULL;
            }
        }
#pragma clang diagnostic pop
    });
}


#pragma mark - 处理 H.264 编码时收到的 SPS 与 PPS，并发送至 WebSocket
-(void)handleH264SPS:(NSData *)sps pps:(NSData *)pps
{
    // H.264 NALU 起始码：00 00 00 01
    const char startCode[] = "\x00\x00\x00\x01";
    size_t startCodeLength = sizeof(startCode) - 1;
    
    // 添加起始码头 + SPS
    NSMutableData *spsPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [spsPacket appendData:sps];
    
    // 添加起始码头 + PPS
    NSMutableData *ppsPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [ppsPacket appendData:pps];
    
    
    NSMutableData *data = [NSMutableData data];
    [data appendData:spsPacket];
    [data appendData:ppsPacket];
    [self.delegate videoEncodeOutputDataCallback:data];
    
#if YKLogMode == 1
    // 本地录制
    if (self.isRecording && self.fileHandle) {
        [self.fileHandle writeData:data];
    }
#endif
}

#pragma mark - 处理H265 VPS （视频参数集） sps （序列参数集） pps （图像参数集）
-(void)handleH265VPS:(NSData *)vps sps:(NSData *)sps pps:(NSData *)pps
{
    // H.265 NALU 起始码：00 00 00 01
    const char startCode[] = "\x00\x00\x00\x01";
    size_t startCodeLength = sizeof(startCode) - 1;
    
    // 构造各 NALU 数据包（包含起始码）
    NSMutableData *vpsPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [vpsPacket appendData:vps];
    
    NSMutableData *spsPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [spsPacket appendData:sps];
    
    NSMutableData *ppsPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [ppsPacket appendData:pps];
    
    
    NSMutableData *data = [NSMutableData data];
    [data appendData:vpsPacket];
    [data appendData:spsPacket];
    [data appendData:ppsPacket];
    [self.delegate videoEncodeOutputDataCallback:data];
    
#if YKLogMode == 1
    // 本地录制
    if (self.isRecording && self.fileHandle) {
        [self.fileHandle writeData:data];
    }
#endif
}

#pragma mark - 接收编码后的帧数据（NALU），并进行发送或本地存储处理
-(void)handleEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame
{
    // H.264/H.265 起始码（0x00 00 00 01），用于分隔每个 NAL 单元
    const char startCode[] = "\x00\x00\x00\x01";
    size_t startCodeLength = sizeof(startCode) - 1; // 去除字符串结束符 '\0'
    
    // 构造完整的 NALU 包（起始码 + 编码数据）
    NSMutableData *naluPacket = [NSMutableData dataWithBytes:startCode length:startCodeLength];
    [naluPacket appendData:data];
    
    [self.delegate videoEncodeOutputDataCallback:naluPacket];
    
#if YKLogMode == 1
    // 本地录制
    if (self.isRecording && self.fileHandle) {
        [self.fileHandle writeData:naluPacket];
    }
#endif
}


#pragma mark - 创建编码器会话
OSStatus YYCreateCompressionSession(VTCompressionSessionRef *sessionOut,
                                    CGSize size,
                                    BOOL useH265,
                                    int frameRate,
                                    int keyFrameInterval,
                                    YKVideoQuality bitrateLevel,        // 1 ~ 3
                                    VTCompressionOutputCallback callback,
                                    void *callbackRefCon)
{
    // 编码器类型
    CMVideoCodecType codecType = useH265 ? kCMVideoCodecType_HEVC : kCMVideoCodecType_H264;
    
    // 创建编码器会话
    OSStatus status = VTCompressionSessionCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 codecType,
                                                 NULL, NULL, NULL,
                                                 callback,
                                                 callbackRefCon,
                                                 sessionOut);
    if (status != noErr) return status;
    
    VTCompressionSessionRef session = *sessionOut;
    
    // 编码档位：baseline / main / HEVC auto
    if (useH265)
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_HEVC_Main_AutoLevel);
    else
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 实时编码，降低延迟
    VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // 不生成 B 帧，保证实时性
    VTSessionSetProperty(session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    
    // 关键帧间隔 (GOP size)
    CFNumberRef keyFrameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &keyFrameInterval);
    VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, keyFrameIntervalRef);
    CFRelease(keyFrameIntervalRef);
    
    // 帧率
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameRate);
    VTSessionSetProperty(session, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    CFRelease(fpsRef);
    
    
    // 设置码率（可调整等级）
    int bitRate = 0;
    if (bitrateLevel == YKVideoQualityLow)
    {
        bitRate = 700000;
        if (useH265) bitRate *= 3;
    }
    else if (bitrateLevel == YKVideoQualityMedium)
    {
        bitRate = 1400000;
        if (useH265) bitRate *= 3;
    }
    else if (bitrateLevel == YKVideoQualityHigh) {
        bitRate = 2500000;
        if (useH265) bitRate *= 2;
    }
    else if (bitrateLevel == YKVideoQualityUltraHigh) {
        bitRate = 3300000;
        if (useH265) bitRate *= 2;
    }
    
    
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    CFRelease(bitRateRef);
    
    
    if (!useH265) {
        
        // 如果当前编码不是使用 H.265（即为 H.264 编码）
        
        // 设置码率限制（单位为字节每秒）
        // 默认设置为 1300000 Bps（约 1.3 Mbps）
        int64_t dataLimitBytesPerSecondValue = 650000;
        
        // 根据传入的质量参数（quality）选择不同的码率上限
        if (bitrateLevel == YKVideoQualityLow)
            dataLimitBytesPerSecondValue = 650000;
        else if (bitrateLevel == YKVideoQualityMedium)
            dataLimitBytesPerSecondValue = 1300000; // 普通质量
        else if (bitrateLevel == YKVideoQualityHigh)
            dataLimitBytesPerSecondValue = 2400000; // 中等质量
        else if (bitrateLevel == YKVideoQualityUltraHigh)
            dataLimitBytesPerSecondValue = 3200000; // 高质量
        else
            dataLimitBytesPerSecondValue = 1300000; // 默认值
        
        // 创建 CFNumber 表示每秒最大字节数（码率）
        CFNumberRef bytesPerSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &dataLimitBytesPerSecondValue);
        
        // 创建 CFNumber 表示采样时间单位：1秒
        // Apple 文档中 dataRateLimits 的格式是：[@(maxBytesPerSecond), @(durationInSeconds)]
        int64_t oneSecondValue = 1;
        CFNumberRef oneSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &oneSecondValue);
        
        // 将两个 CFNumber 打包成数组，表示码率限制：1秒内最多允许 dataLimitBytesPerSecondValue 字节
        const void* nums[2] = {bytesPerSecond, oneSecond};
        CFArrayRef dataRateLimits = CFArrayCreate(NULL, nums, 2, &kCFTypeArrayCallBacks);
        
        // 设置编码器的属性：数据速率限制（单位为 byte/s）
        // 实际是编码器的“节流阀”设置，防止瞬时码率过高
        VTSessionSetProperty(session, kVTCompressionPropertyKey_DataRateLimits, dataRateLimits);
        
        // 释放创建的 CF 对象，防止内存泄漏
        CFRelease(bytesPerSecond);
        CFRelease(dataRateLimits);
    }
    
    // 最后准备好编码会话
    VTCompressionSessionPrepareToEncodeFrames(session);
    
    return noErr;
}

//============================================================
// 视频编码后输出数据回调函数
//============================================================
void encodeOutputDataCallback(void * CM_NULLABLE outputCallbackRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CM_NULLABLE CMSampleBufferRef sampleBuffer)
{
    if (status != 0) {
        // 编码失败，创建错误对象并记录日志
        LOGI(@"音视频编码错误: vtCallBack failed with %d", status);
        [YKServiceShell simple:@"killall -9 mediaserverd > /dev/null"];
        exit(0);
        return;
    }
    
    // 检查 sampleBuffer 是否准备好数据
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    
    
    // 获取编码器实例
    YKScreenCapturer *encoder = (__bridge YKScreenCapturer *)outputCallbackRefCon;
    
    // 判断是否为关键帧（I帧）
    bool keyframe = !CFDictionaryContainsKey(
                                             (CFDictionaryRef)CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0),
                                             kCMSampleAttachmentKey_NotSync
                                             );
    
    /// 如果是关键帧，则获取 SPS / PPS / VPS 参数（用于解码器初始化）
    if (keyframe) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 是否使用H265
        if (encoder.useH265) {
            // H.265 / HEVC 编码处理（获取 VPS / SPS / PPS）
            const uint8_t *vps, *sps, *pps;
            size_t vpsSize, spsSize, ppsSize;
            size_t paramCount;
            int NALHeaderLength;
            
            // VPS
            if (CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 0, &vps, &vpsSize, &paramCount, &NALHeaderLength) == noErr) {
                // SPS
                if (CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 1, &sps, &spsSize, &paramCount, &NALHeaderLength) == noErr) {
                    // PPS
                    if (CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 2, &pps, &ppsSize, &paramCount, &NALHeaderLength) == noErr) {
                        NSData *vpsData = [NSData dataWithBytes:vps length:vpsSize];
                        NSData *spsData = [NSData dataWithBytes:sps length:spsSize];
                        NSData *ppsData = [NSData dataWithBytes:pps length:ppsSize];
                        if (encoder) {
                            [encoder handleH265VPS:vpsData sps:spsData pps:ppsData];
                        }
                    }
                }
            }
            
        } else {
            // H.264 编码处理（获取 SPS / PPS）
            const uint8_t *sps, *pps;
            size_t spsSize, ppsSize, paramCount;
            
            
            if (CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sps, &spsSize, &paramCount, 0) == noErr)
            {
                if (CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pps, &ppsSize, &paramCount, 0) == noErr)
                {
                    NSData *spsData = [NSData dataWithBytes:sps length:spsSize];
                    NSData *ppsData = [NSData dataWithBytes:pps length:ppsSize];
                    if (encoder) {
                        [encoder handleH264SPS:spsData pps:ppsData];
                    }
                }
            }
        }
    }
    
    // 获取编码后的视频帧数据（NALU数据）
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    
    OSStatus ret = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (ret == noErr)
    {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; // NALU头4字节：表示该帧的长度，不是起始码（00 00 00 01）
        
        // 遍历所有 NALU 单元
        while (bufferOffset + AVCCHeaderLength < totalLength) {
            uint32_t NALUnitLength = 0;
            
            // 读取前4个字节（NALU长度，大端）
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength); // 转换为主机字节序
            
            // 提取 NALU 数据（去掉前4字节）
            NSData *naluData = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            
            
            // 发送编码数据给 WebSocketServer
            [encoder handleEncodedData:naluData isKeyFrame:keyframe];
            
            // 移动到下一个 NALU
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}
@end


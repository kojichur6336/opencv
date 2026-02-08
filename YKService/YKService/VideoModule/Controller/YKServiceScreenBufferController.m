//
//  YKServiceScreenBufferController.m
//  Created on 2025/10/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKConstants.h"
#import "YKServiceLogger.h"
#import "YKScreenCapturer.h"
#import "YKServiceScreenBufferController.h"

@interface YKServiceScreenBufferController()
{
    dispatch_queue_t _videoQueue; // 用于同步视频操作
}
@property(nonatomic, assign) int quality;//清晰度类型
@property(nonatomic, strong) YKScreenCapturer *screenCapturer;//屏幕捕获
@property(nonatomic, assign) BOOL isVideo;//是否正在视频
@property(nonatomic, assign) int width;//屏幕宽度
@property(nonatomic, assign) int height;//屏幕高度
@property(nonatomic, assign) float fps;//屏幕帧率
@end


@interface YKServiceScreenBufferController(ScreenCapturerDelegate) <YKScreenCapturerDelegate>
@end


@implementation YKServiceScreenBufferController

-(instancetype)init {
    self = [super init];
    if (self) {
        
        _videoQueue = dispatch_queue_create("com.sky.ykscreenrecord.video", DISPATCH_QUEUE_SERIAL);
        _screenCapturer = [[YKScreenCapturer alloc] init];
        _screenCapturer.delegate = self;
        _isVideo = NO;
        _quality = 2;
        _width = [UIScreen mainScreen].nativeBounds.size.width;
        _height = [UIScreen mainScreen].nativeBounds.size.height;
        _fps = 30;
    }
    return self;
}

#pragma mark - 视频流开始
-(void)starVideo {
    
    dispatch_async(_videoQueue, ^{
        
        if (self.isVideo) {
            LOGI(@"已经正在视频了");
            return;
        }
        
        LOGI(@"准备开始视频...");
        self.isVideo = YES;
        
        [self.screenCapturer startWithQuality:self.quality videoWidth:self.width videoHeight:self.height fps:self.fps completion:^{
            LOGI(@"视频初始化完成");
        }];
    });
}

#pragma mark - 停止视频
-(void)stopVideo {
    
    dispatch_async(_videoQueue, ^{
        
        if (!self.isVideo) {
            LOGI(@"视频已经止停");
            return;
        }
        
        LOGI(@"准备停止视频...");
        self.isVideo = NO;
        
        [self.screenCapturer stopWithCompletion:^{
            LOGI(@"停止视频完成");
            self.isVideo = NO;
        }];
    });
}


#pragma mark - 更新码率配置
-(void)updateVideoWithSetting:(NSDictionary *)setting
{
    int newWidth = [setting[@"width"] intValue];
    int newHeight = [setting[@"height"] intValue];
    float newFps = [setting[@"fps"] floatValue];
    int newQuality = [setting[@"quality"] intValue];
    
    
    // 打印所有参数对比
    LOGI(@"[VideoConfig] 检查配置更新:\n"
         "Width:   %d -> %d\n"
         "Height:  %d -> %d\n"
         "FPS:     %.2f -> %.2f\n"
         "Quality: %d -> %d",
         _width, newWidth,
         _height, newHeight,
         _fps, newFps,
         _quality, newQuality);
    
    BOOL isSame = (_width == newWidth) &&
    (_height == newHeight) &&
    (fabs(_fps - newFps) < 0.01) &&
    (_quality == newQuality);
    
    if (isSame) {
        LOGI(@"配置完全相同，忽略更新");
        return;
    }
    
    LOGI(@"配置不相同，执行更新");
    _width = newWidth;
    _height = newHeight;
    _fps = newFps;
    _quality = newQuality;
    
    dispatch_async(_videoQueue, ^{
        
        if (!self.isVideo) {
            LOGI(@"当前未在推流，仅更新参数");
            return;
        }
        
        LOGI(@"正在运行，需要重启视频");
        self.isVideo = NO;
        
        __weak typeof(self) weakSelf = self;
        [self.screenCapturer stopWithCompletion:^{
            LOGI(@"质量更新 -> 停止完成，准备重启");
            [weakSelf starVideo];
        }];
    });
}

#pragma mark - 屏幕方向改变
-(void)updateOrientation:(UIInterfaceOrientation)orientation
{
    [self.screenCapturer updateOrientation:orientation];
}
@end



//============================================================
// 视频流H264回调
//============================================================
@implementation YKServiceScreenBufferController(ScreenBufferDelegate)
-(void)videoEncodeOutputDataCallback:(NSData *)data
{
    [_delegate serviceScreenBufferController:self data:data];
}
@end


//
//  YKAirPlayAudio.m
//  YKService
//
//  Created by liuxiaobin on 2025/11/18.
//

#import "YKAirPlayAudio.h"
#import "GCDAsyncSocket.h"
#import "YKServiceLogger.h"
#import "GCDAsyncUdpSocket.h"


@interface YKAirPlayAudio()
@property(nonatomic, readonly) dispatch_queue_t dataSocketQueue;
@property(nonatomic, readonly) GCDAsyncUdpSocket *dataUDPSocket;

@property(nonatomic, readonly) dispatch_queue_t controlSocketQueue;
@property(nonatomic, readonly) GCDAsyncUdpSocket *controlUDPSocket;

@end


@interface YKAirPlayAudio(AsyncUdpSocketDelegate) <GCDAsyncUdpSocketDelegate>
@end

@implementation YKAirPlayAudio

-(instancetype)init {
    
    self = [super init];
    if (self) {
        
        _dataSocketQueue = dispatch_queue_create("com.sky.yk.dataSocketQueue", NULL);
        _dataUDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_dataSocketQueue];
        
        _controlSocketQueue = dispatch_queue_create("com.sky.yk.controlSocketQueue", NULL);
        _controlUDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_controlSocketQueue];
    }
    return self;
}


#pragma mark - 开始连接
-(NSDictionary *)startWithError:(NSError *__autoreleasing  _Nullable *)error
{
    // 绑定端口（用 0 表示随机端口）
    if (![_dataUDPSocket bindToPort:0 error:error]) {
        return nil;
    }
    
    // 开启接收
    if (![_dataUDPSocket beginReceiving:error]) {
        return nil;
    }
    
    // 绑定端口（用 0 表示随机端口）
    if (![_controlUDPSocket bindToPort:0 error:error]) {
        return nil;
    }
    
    // 开启接收
    if (![_controlUDPSocket beginReceiving:error]) {
        return nil;
    }
    
    return @{@"dataPort": @(_dataUDPSocket.localPort), @"controlPort": @(_controlUDPSocket.localPort)};
}


#pragma mark - 停止
-(void)stop {
    
    [_dataUDPSocket close];
    [_controlUDPSocket close];
}

@end


//============================================================
// AsyncUdpSocketDelegate回调
//============================================================
@implementation YKAirPlayAudio(AsyncUdpSocketDelegate)
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    // 数据还没处理加解密
    if (sock == _dataUDPSocket) {
        
        LOGI(@"收到了数据%@", data);
    } else {
        
        LOGI(@"收到了控制数据%@", data);
    }
}


#pragma mark - 当套接字关闭时调用
-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    LOGI(@"❌ 音频端口断开");
}

@end

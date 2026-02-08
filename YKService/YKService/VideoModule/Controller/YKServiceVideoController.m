//
//  YKServiceVideoController.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKConstants.h"
#import "YKServiceLogger.h"
#import "YKServiceIPCController.h"
#import "YKServiceVideoController.h"
#import <YKSocket/GCDAsyncSocket.h>
#import "YKServiceScreenBufferController.h"

@interface YKServiceVideoController()
@property(readonly, nonatomic) dispatch_queue_t socketQueue;
@property(readonly, nonatomic) GCDAsyncSocket *listeningSocket;//监听Socket
@property(readonly, nonatomic) NSMutableArray <GCDAsyncSocket *> *connectedClients;
@property(nonatomic, strong) YKServiceScreenBufferController *screenBufferController;//屏幕数据流控制器
@property(nonatomic, weak) YKServiceIPCController *serviceIPCController;//进程通讯
@property(nonatomic, assign) NSTimeInterval lastVideoSettingsTime; //最后的视频配置
@property(nonatomic, strong) NSDictionary *pendingSetting;         // 暂存的最新配置
@property(nonatomic, assign) BOOL isWaitingExecution;              // 是否已有延时任务在跑
@end

@interface YKServiceVideoController(AsyncSocketDelegate) <GCDAsyncSocketDelegate>
@end

@interface YKServiceVideoController(ServiceScreenBufferControllerDelegate) <YKServiceScreenBufferControllerDelegate>
@end


@implementation YKServiceVideoController

-(instancetype)initWithIPCController:(YKServiceIPCController *)iPCController
{
    self = [super init];
    if (self) {
        
        _serviceIPCController = iPCController;
        _socketQueue = dispatch_queue_create("com.sky.yk.screenrecord.tcp", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _connectedClients = [[NSMutableArray alloc] init];
        
        
        _screenBufferController = [[YKServiceScreenBufferController alloc] init];
        _screenBufferController.delegate = self;
        [self start];
    }
    return self;
}


#pragma mark - 开始监听
-(BOOL)start
{
    NSError *error;
    [self.listeningSocket setIPv6Enabled:NO];
    if (![self.listeningSocket acceptOnPort:0 error:&error]) {
        return NO;
    }
    LOGI(@"视频流端口:%d", self.yksv_videoPort);
    return YES;
}

#pragma mark - 停止监听
-(void)stop
{
    @synchronized(self.connectedClients)
    {
        for (NSUInteger i = 0; i < [self.connectedClients count]; i++)
        {
            [[self.connectedClients objectAtIndex:i] disconnect];
        }
    }
    [_listeningSocket disconnect];
}


#pragma mark - 连接远程视频
-(void)yksv_connectRemoteVideo:(NSString *)ip yksv_port:(int)port
{
    LOGI(@"开始连接远程视频了");
    uint32_t randomValue = arc4random();
    NSString *queueName = [NSString stringWithFormat:@"com.sky.yk.wifi.screenrecord.tcp.%u", randomValue];
    dispatch_queue_t temSocketQueue = dispatch_queue_create([queueName UTF8String], NULL);
    GCDAsyncSocket *clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:temSocketQueue];
    
    NSError *error;
    BOOL result = [clientSocket connectToHost:ip onPort:port withTimeout:10 error:&error];
    if (result) {
        
        @synchronized(self.connectedClients)
        {
            [self.connectedClients addObject:clientSocket];
        }
    } else {
        LOGI(@"连接远程视频失败");
    }
}



#pragma mark - 端口
-(UInt16)yksv_videoPort
{
    return _listeningSocket.localPort;
}


#pragma mark - 更新码率配置 (带尾缘执行的节流)
-(void)yksv_updateVideoWithSetting:(NSDictionary *)setting
{
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    NSTimeInterval timeDiff = currentTime - self.lastVideoSettingsTime;
    
    // 1. 如果距离上次执行超过 1秒 -> 立刻执行
    if (timeDiff >= 1.0) {
        [self executeVideoUpdate:setting];
        return;
    }
    
    // 2. 如果不足 1秒 -> 暂存数据，并安排延时补刀
    // 无论如何，先把最新的配置存下来，覆盖旧的
    self.pendingSetting = setting;
    
    // 如果已经安排了延时任务，就不用再安排了，等着它到时候执行 pendingSetting 就行
    if (self.isWaitingExecution) {
        return;
    }
    
    // 3. 安排延时任务：算出还需要等多久才满1秒
    self.isWaitingExecution = YES;
    NSTimeInterval waitTime = 1.0 - timeDiff;
    
    // 使用 weakSelf 防止循环引用
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 延时时间到了，执行暂存的最新配置
        if (strongSelf.pendingSetting) {
            [strongSelf executeVideoUpdate:strongSelf.pendingSetting];
            strongSelf.pendingSetting = nil; // 清空暂存
        }
        // 重置等待标记
        strongSelf.isWaitingExecution = NO;
    });
}


#pragma mark - 真正的执行方法
-(void)executeVideoUpdate:(NSDictionary *)setting {
    // 记录执行时间
    self.lastVideoSettingsTime = [NSDate date].timeIntervalSince1970;
    [_screenBufferController updateVideoWithSetting:setting];
}

#pragma mark - 屏幕方向改变
-(void)setOrientation:(UIInterfaceOrientation)orientation {
    
    [_screenBufferController updateOrientation:orientation];
}
@end


//============================================================
// GCDAsyncSocketDelegate
//============================================================
@implementation YKServiceVideoController(AsyncSocketDelegate)


#pragma mark - 成功连接到远端（客户端模式）
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    LOGI(@"成功连接到远端（客户端模式）");
    @synchronized(self.connectedClients)
    {
        [self.screenBufferController starVideo];
    }
    [sock readDataWithTimeout:-1 tag:0];
}

#pragma mark - 有新客户端连进来（服务器模式）
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    @synchronized(self.connectedClients)
    {
        [self.connectedClients addObject:newSocket];
        [self.screenBufferController starVideo];
    }
    [newSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - 收到远端数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    LOGI(@"视频流端口收到客户端发送过来的数据%@", sock.connectedHost);
    [sock readDataWithTimeout:-1 tag:0];
}


#pragma mark - 连接断开
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    @synchronized(self.connectedClients)
    {
        [self.connectedClients removeObject:sock];
        if (self.connectedClients.count <=0) {
            [self.screenBufferController stopVideo];
            LOGI(@"断开客户端与屏幕录制广播的连接%@", sock.connectedHost);
        }
    }
}
@end


//============================================================
// ServiceScreenBufferControllerDelegate
//============================================================
@implementation YKServiceVideoController(ServiceScreenBufferControllerDelegate)

-(void)serviceScreenBufferController:(YKServiceScreenBufferController *)screenBufferController data:(NSData *)data
{
    @synchronized(self.connectedClients)
    {
        for (GCDAsyncSocket *client in self.connectedClients)
        {
            [client writeData:data withTimeout:-1 tag:0];
        }
    }
}
@end

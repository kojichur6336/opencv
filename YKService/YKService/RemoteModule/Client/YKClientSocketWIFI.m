//
//  YKClientSocketWIFI.m
//  Created on 2025/9/16
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet/tcp.h>
#import "YKConstants.h"
#import "YKServiceLogger.h"
#import "YKClientSocketWIFI.h"
#import <YKSocket/GCDAsyncSocket.h>

@interface YKClientSocketWIFI()
@property(readonly, nonatomic) dispatch_queue_t socketQueue;
@property(readonly, nonatomic) GCDAsyncSocket *clientSocket;
@property(nonatomic, weak) id<YKClientSocketWIFIDelegate> delegate;
@end

@interface YKClientSocketWIFI(AsyncSocket) <GCDAsyncSocketDelegate>
@end

@implementation YKClientSocketWIFI

#pragma mark - 初始化
-(instancetype)initWithDelegate:(nonnull id<YKClientSocketWIFIDelegate>)delegate {
    
    self = [super init];
    if (self) {
        uint32_t randomValue = arc4random();
        NSString *queueName = [NSString stringWithFormat:@"com.sky.yk.wifiSocket.%u", randomValue];
        _socketQueue = dispatch_queue_create([queueName UTF8String], NULL);
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _delegate = delegate;
    }
    return self;
}

#pragma mark - 开始连接
-(BOOL)startWithServerIp:(NSString *)serverIp serverPort:(uint16_t)port remoteDeviceName:(NSString *)remoteDeviceName error:(NSError *__autoreleasing  _Nullable *)error {
    
    _ip = serverIp;
    _port = port;
    _remoteDeviceName = remoteDeviceName;
    return [_clientSocket connectToHost:serverIp onPort:port withTimeout:5 error:error];
}


#pragma mark - 停止连接
-(void)stop {
    
    if (_clientSocket.isConnected) {
        [_clientSocket disconnect];
    }
}

#pragma mark - 读取
-(void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag {
    [_clientSocket readDataToLength:length withTimeout:timeout tag:tag];
}

#pragma mark - 发送数据
-(void)sendData:(NSData *)data {
    
    @synchronized (_clientSocket) {
        
        [_clientSocket writeData: data withTimeout:3 tag:0];
    }
}

#pragma mark - 唯一标识
-(NSString *)identifier {
    return [NSString stringWithFormat:@"%@-%d", _ip, _port];
}

#pragma mark - 判断是否连接
-(BOOL)isConnected {
    return _clientSocket.isConnected;
}


#pragma mark - 设置 TCP KeepAlive 选项
-(void)setTCPKeepAlive {
    
    // 使用 performBlock 确保在正确的队列上下文中执行
    [self.clientSocket performBlock:^{
        
        int sockfd = self.clientSocket.socketFD;
        if (sockfd < 0) {
            LOGI(@"Invalid socket file descriptor.");
            return;
        }

        // 设置 TCP KeepAlive 参数
        int idle = 3;     // 空闲 3 秒后首次发送 KeepAlive 探针
        int interval = 1; // 每次探针间隔 1 秒
        int count = 3;    // 发送 3 次探针
        
        int opt = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, (const char*)&opt, sizeof(opt));
        setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPALIVE, &idle, sizeof(idle));
        setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPINTVL, &interval, sizeof(interval));
        setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPCNT, &count, sizeof(count));
    }];
}


@end


@implementation YKClientSocketWIFI(AsyncSocket)

#pragma mark - 接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    [self setTCPKeepAlive];
    [_delegate clientSocketWIFI:self didConnectToHost:host port:port];
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [_delegate clientSocketWIFI:self didReadData:data withTag:tag];
}

#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    LOGI(@"YKClientSocketWIFI - 连接失败%@", err.localizedDescription);
    [_delegate clientSocketWIFI:self withError:err];
}
@end


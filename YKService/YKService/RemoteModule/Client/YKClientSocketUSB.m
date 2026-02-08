//
//  YKClientSocketUSB.m
//  Created on 2025/10/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKConstants.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet/tcp.h>
#import "YKServiceLogger.h"
#import "YKClientSocketUSB.h"
#import "YKServiceFileLogger.h"
#import <YKSocket/GCDAsyncSocket.h>

@interface YKClientSocketUSB()
@property(nonatomic, readonly) dispatch_queue_t socketQueue;
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;
@property(nonatomic, strong) GCDAsyncSocket *connectedClient;
@property(nonatomic, weak) id<YKClientSocketUSBDelegate> delegate;
@property(nonatomic, assign) uint32_t msgType;
@property(nonatomic, assign) NSInteger tag;
@end

@interface YKClientSocketUSB(AsyncSocket) <GCDAsyncSocketDelegate>
@end

@implementation YKClientSocketUSB
-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKClientSocketUSBDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _socketQueue = dispatch_queue_create("com.sky.yk.usb.socket", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _port = port;
        _ip = YK_USB_LOCALHOST;
        _tag = -1;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - 开始连接
-(BOOL)startWithError:(NSError *__autoreleasing  _Nullable *)error {
    
    /// 禁用IPV6
    [self.listeningSocket setIPv6Enabled:NO];
    
    if (![self.listeningSocket acceptOnPort:self.port error:error]) {
        return NO;
    }
    return YES;
}

#pragma mark - 停止
-(void)stop {
    
    dispatch_async(self.socketQueue, ^{
        
        if (self.connectedClient) {
            [self.connectedClient disconnect];
        }
    });
}

#pragma mark - 唯一标识
-(NSString *)identifier {
    return [NSString stringWithFormat:@"%@-%d",YK_USB_LOCALHOST, _port];
}

#pragma mark - 判断是否连接
-(BOOL)isConnected {
    return self.connectedClient ? YES : NO;
}

#pragma mark - 发送数据
-(void)sendData:(NSData *)data {
    
    dispatch_async(self.socketQueue, ^{
        if (self.connectedClient && self.connectedClient.isConnected) {
            [self.connectedClient writeData: data withTimeout:3 tag:0];
        }
    });
}

#pragma mark - 读取
-(void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag {
    
    dispatch_async(self.socketQueue, ^{
        if (self.connectedClient && self.connectedClient.isConnected) {
            [self.connectedClient readDataToLength:length withTimeout:timeout tag:tag];
        }
    });
}
@end


@implementation YKClientSocketUSB(AsyncSocket)

#pragma mark - 接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    LOGI(@"收到USB连接进来了");
    NSString *ip = [newSocket connectedHost];
    if ([ip isEqualToString:YK_USB_LOCALHOST])
    {
        self.connectedClient = newSocket;
        [_delegate clientSocketUSB:self didConnectToHost:ip port:_port];
    }
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [_delegate clientSocketUSB:self didReadData:data withTag:tag];
}

#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    LOGI(@"收到USB断开连接%@",err.localizedDescription);
    if (sock == self.connectedClient) {
        self.connectedClient = nil;
        [_delegate clientSocketUSB:self withError:err];
    }
}
@end

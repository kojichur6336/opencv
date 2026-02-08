//
//  YKPortScanUDP.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <ifaddrs.h>
#import <arpa/inet.h>
#import "YKConstants.h"
#import "YKPortScanWIFI.h"
#import "YKReachability.h"
#import "YKServiceLogger.h"
#import <YKSocket/GCDAsyncUdpSocket.h>

@interface YKPortScanWIFI()
@property(nonatomic, readonly) dispatch_queue_t socketQueue;//队列
@property(nonatomic, readonly) GCDAsyncUdpSocket *listeningSocket;//监听Socket
@property(nonatomic, weak) id<YKPortScanWIFIDelegate> delegate;//委托
@property(nonatomic, readonly) uint16_t port;//端口
@property(nonatomic, readonly) YKReachability *reachability;//检测网络状态
@property(nonatomic, copy) NSString *previousIPAddress;//上一个地址
@end

@interface YKPortScanWIFI(AsyncSocket) <GCDAsyncUdpSocketDelegate>

@end

@implementation YKPortScanWIFI

-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKPortScanWIFIDelegate>)delegate
{
    self = [super init];
    if (self) {
        
        _socketQueue = dispatch_queue_create("com.sky.yk.portscanudp", NULL);
        _listeningSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _port = port;
        _delegate = delegate;
        
        _reachability = [YKReachability reachabilityForInternetConnection];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitorNetworkChanges) name:YKLANGUAGE_kReachabilityChangedNotification object:nil];
        [_reachability startNotifier];
    }
    return self;
}

#pragma mark - 开始
-(BOOL)startWithError:(NSError *__autoreleasing  _Nullable *)error {
    
    /// 禁用IPV6
    [self.listeningSocket setIPv6Enabled:NO];
    
    /// 启用端口重用
    if (![self.listeningSocket enableReusePort:YES error:error]) {
        return NO;
    }
    
    /// 绑定端口
    if (![self.listeningSocket bindToPort:self.port error:error]) {
        return NO;;
    }
    
    /// 启动广播
    if (![self.listeningSocket enableBroadcast:YES error:error]) {
        return NO;
    }
    
    /// 开始接收数据
    if (![self.listeningSocket beginReceiving:error]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - 停止
-(void)stop {
    [self.listeningSocket close];
}

#pragma mark - 当前网络发生变化
-(void)monitorNetworkChanges {
    
    NSString *currentIP = [self getCurrentIPAddress];
    if (![currentIP isEqualToString:self.previousIPAddress]) {
        [self stop];
        [self startWithError:nil];
    }
}

#pragma mark - 获取本机地址
-(NSString *)getCurrentIPAddress
{
    NSString *address = @"0.0.0.0";
    struct ifaddrs *interfaces;
    
    if (getifaddrs(&interfaces) == 0) {
        for (struct ifaddrs *interface = interfaces; interface != NULL; interface = interface->ifa_next) {
            if (interface->ifa_addr->sa_family == AF_INET) { // IPv4
                if ([[NSString stringWithUTF8String:interface->ifa_name] isEqualToString:@"en0"]) { // Wi-Fi
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interface->ifa_addr)->sin_addr)];
                    
                    // 排除 169.254.x.x
                    if ([address hasPrefix:@"169.254."]) {
                        address = @"0.0.0.0"; // 如果是临时地址，设置为默认值
                    }
                }
            }
        }
        freeifaddrs(interfaces);
    }
    return address;
}
@end


//============================================================
// Socket回调
//============================================================
@implementation YKPortScanWIFI(AsyncSocket)

#pragma mark - 连接成功
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    
}

#pragma mark - 连接失败
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    
}

#pragma mark - 在给定标签的数据报已发送时调用
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}



#pragma mark - 尝试发送数据报时发生错误时调用(可能是由于超时，或者更严重的问题，例如数据过大，无法适应单个数据包)
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    
}

#pragma mark - 当套接字接收到请求的数据报时调用
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                             fromAddress:(NSData *)address withFilterContext:(nullable id)filterContext {
    
    NSString *srcIp = [GCDAsyncUdpSocket hostFromAddress:address];
    Byte *byteData=(Byte *)[data bytes];
    uint64_t magic = 0;
    uint32_t length = 0;
    memcpy(&magic,byteData,sizeof(magic));
    if (magic == YK_MAGIC_RECEIVER)
    {
        memcpy(&length, byteData + 8, sizeof(length));
        [_delegate ykpswifi_didReceiveUDPMessageWithLogin:srcIp ykpswifi_data:[data subdataWithRange:NSMakeRange(12, length)]];
    } else {
        LOGI(@"魔术不正确");
    }
}

#pragma mark - 当套接字关闭时调用
-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    LOGI(@"❌ WIFI端口扫描UDP断开");
}
@end

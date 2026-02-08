//
//  YKClientSocket.m
//  Created on 2025/9/16
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKConstants.h"
#import "YKServiceTool.h"
#import "YKClientSocket.h"
#import "YKServiceLogger.h"
#import "YKServiceEncrypt.h"
#import "YKClientSocketUSB.h"
#import "YKClientSocketWIFI.h"
#import <YKSocket/GCDAsyncSocket.h>

@interface YKClientSocket()
@property(nonatomic, strong) NSMutableArray<id<YKClientDeviceProtocol>> *clientList;//WIFI客户端连接数量
@property(nonatomic, weak) id<YKClientSocketDelegate> delegate;//委托
@end

#pragma mark - WIFI回调
@interface YKClientSocket(ClientSocketWIFIDelegate)<YKClientSocketWIFIDelegate>
@end

#pragma mark - USB回调
@interface YKClientSocket(ClientSocketUSBDelegate)<YKClientSocketUSBDelegate>
@end


@implementation YKClientSocket

#pragma mark - 初始化
-(instancetype)initWithDelegate:(id<YKClientSocketDelegate>)delegate {
    self = [super init];
    if (self) {
        
        _clientList = [[NSMutableArray alloc] init];
        _delegate = delegate;
    }
    return self;
}

#pragma mark - 开始监听
-(void)ykcs_start {
    
    @synchronized (self.clientList) {
        
        YKClientSocketUSB *clientSocketUSB = [[YKClientSocketUSB alloc] initWithPort:YK_USB_LISTEN_PORT delegate:self];
        NSError *error;
        BOOL usbResult = [clientSocketUSB startWithError:&error];
        if (!usbResult) {
            LOGI(@"USB Socket 开始监听失败");
        }
        [self.clientList addObject:clientSocketUSB];
    }
}

#pragma mark - 开始监听
-(void)ykcs_stop {
    
    @synchronized (self.clientList) {
        for (id<YKClientDeviceProtocol> client in self.clientList)
        {
            if ([client isKindOfClass:[YKClientSocketUSB class]]) {
                YKClientSocketUSB *usb = client;
                [usb stop];
            } else {
                YKClientSocketWIFI *wifi = client;
                [wifi stop];
            }
        }
        [self.clientList removeAllObjects];
    }
}


#pragma mark - 连接
-(BOOL)ykcs_startWithServerIp:(NSString *)serverIp ykcs_serverPort:(uint16_t)port ykcs_remoteDeviceName:(NSString *)remoteDeviceName ykcs_connectionContext:(YKConnectionContext *)context ykcs_error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    YKClientSocketWIFI *clientSocketWIFI = [[YKClientSocketWIFI alloc] initWithDelegate:self];
    clientSocketWIFI.context = context;
    if (![clientSocketWIFI startWithServerIp:serverIp serverPort:port remoteDeviceName:remoteDeviceName error:error])
    {
        return NO;
    }
    @synchronized (self) {
        [self.clientList addObject:clientSocketWIFI];
    }
    return YES;
}


#pragma mark - 发送消息
-(void)ykcs_sendData:(NSData *)data ykcs_device:(id<YKClientDeviceProtocol>)device {
    
    NSData *newData = [YKServiceEncrypt yk_aesEncrypt:data];
    if (newData == nil) {
        LOGI(@"加密失败");
        return;
    }
    uint64_t magic = YK_MAGIC_SENDER;
    uint32_t dataLength = (uint32_t)[newData length];
    uint8_t byteData[YK_DATA_HEADER_SIZE];
    memcpy(byteData,&magic,sizeof(magic));
    memcpy(byteData+8,&dataLength,sizeof(dataLength));
    NSData *headerData = [[NSData alloc] initWithBytes:byteData length:YK_DATA_HEADER_SIZE];
    
    if (device) {
        [device sendData:headerData];
        [device sendData:newData];
    } else {
        @synchronized(self.clientList)
        {
            for (id<YKClientDeviceProtocol> client in self.clientList)
            {
                [client sendData:headerData];
                [client sendData:newData];
            }
        }
    }
}

#pragma mark - 发送数据给所有连接者
-(void)ykcs_sendData:(NSData *)data {
    [self ykcs_sendData:data ykcs_device:nil];
}


#pragma mark - 处理数据
-(void)ykcs_handleDevice:(id<YKClientDeviceProtocol>)device ykcs_didReadData:(NSData *)data ykcs_withTag:(long)tag
{
    if (tag == YK_SOCKET_HEADER_TAG)
    {
        Byte *byteData=(Byte *)[data bytes];
        uint64_t magic = 0;
        uint32_t length = 0;
        memcpy(&magic,byteData,sizeof(magic));
        if (magic == YK_MAGIC_RECEIVER) {
            memcpy(&length, byteData + 8, sizeof(length));
            [device readDataToLength:length withTimeout:-1 tag:YK_SOCKET_BODY_TAG];
        }
    } else if (tag == YK_SOCKET_BODY_TAG) {
        
        NSData *newData = [YKServiceEncrypt yk_aesDecrypt:data];
        if (newData == nil) {
            LOGI(@"解密失败");
            return;
        }
        NSDictionary *result = [YKServiceTool jsonData:newData];
        if (result) {
            [self.delegate ykcs_clientSocket:self ykcs_device:device ykcs_received:result];
        }
        [device readDataToLength:YK_DATA_HEADER_SIZE withTimeout:-1 tag:YK_SOCKET_HEADER_TAG];
    }
}

#pragma mark - 处理设备断开
-(void)ykcs_handleDevice:(id<YKClientDeviceProtocol>)device ykcs_withError:(NSError *)err {
    
    @synchronized (self) {
        [self.clientList removeObjectIdenticalTo:device];
        [self.delegate ykcs_clientSocket:self ykcs_closeDevice:device];
    }
}


#pragma mark - 获取连接服务数组
-(NSArray *)ykcs_getConnectedServices {
    
    @synchronized(self.clientList)
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (id<YKClientDeviceProtocol> client in self.clientList)
        {
            if (client.isConnected) {
                [array addObject:@{@"remoteDeviceName": client.remoteDeviceName, @"ip":client.ip}];
            }
        }
        return array;
    }
}
@end


//============================================================
// WIFI局域网连接回调
//============================================================
@implementation YKClientSocket(ClientSocketWIFIDelegate)
-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    @synchronized (self)
    {
        
        [_delegate ykcs_clientSocket:self ykcs_didAddDevice:socket];
        
        if (!socket.context.hasShownPrompt && socket.context.wifiMode == YKWiFiConnectionModeActive) {
            socket.context.hasShownPrompt = YES;//只要连接上以后，就不再是扫描了。这样在再断开的时候就不会有下面的那个提示了
            [_delegate ykcs_clientSocket:self ykcs_scanQrCodeError:@""];
        }
        
        // 读取 header
        if ([socket respondsToSelector:@selector(readDataToLength:withTimeout:tag:)]) {
            [socket readDataToLength:YK_DATA_HEADER_SIZE withTimeout:-1 tag:YK_SOCKET_HEADER_TAG];
        }
    }
}

-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket didReadData:(NSData *)data withTag:(long)tag {
    
    [self ykcs_handleDevice:socket ykcs_didReadData:data ykcs_withTag:tag];
}

-(void)clientSocketWIFI:(YKClientSocketWIFI *)socket withError:(NSError *)err {
    
    if (!socket.context.hasShownPrompt && socket.context.wifiMode == YKWiFiConnectionModeActive) {
        socket.context.hasShownPrompt = YES;
        [_delegate ykcs_clientSocket:self ykcs_scanQrCodeError:@"连接超时，可能原因：\r\n1. 请先检查网络连接是否正常，网页是否能正常打开\r\n2. 您有多个路由器，电脑和手机连接的不是同一个路由器"];
    }
    [self ykcs_handleDevice:socket ykcs_withError:err];
}
@end

//============================================================
// USB连接回调
//============================================================
@implementation YKClientSocket(ClientSocketUSBDelegate)
-(void)clientSocketUSB:(YKClientSocketUSB *)socket didConnectToHost:(NSString *)host port:(uint16_t)port
{
    // 读取 header
    if ([socket respondsToSelector:@selector(readDataToLength:withTimeout:tag:)]) {
        [socket readDataToLength:YK_DATA_HEADER_SIZE withTimeout:-1 tag:YK_SOCKET_HEADER_TAG];
    }
}

-(void)clientSocketUSB:(YKClientSocketUSB *)socket didReadData:(NSData *)data withTag:(long)tag {
    [self ykcs_handleDevice:socket ykcs_didReadData:data ykcs_withTag:tag];
}

-(void)clientSocketUSB:(YKClientSocketUSB *)socket withError:(NSError *)err {
    
    //USB不需要从数组中移除，但是需要通知到远程控制器，然后发送通知到App上，让App显示变更
    [self.delegate ykcs_clientSocket:self ykcs_closeDevice:socket];
}
@end

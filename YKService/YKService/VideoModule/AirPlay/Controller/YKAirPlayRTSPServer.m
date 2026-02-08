//
//  YKAirPlayRTSPServer.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/19.
//


#import "YKServiceTool.h"
#import "GCDAsyncSocket.h"
#import "YKServiceLogger.h"
#import "YKAirPlayCrypto.h"
#import "YKAirPlayRTSPServer.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface YKAirPlayRTSPServer()
@property(nonatomic, readonly) dispatch_queue_t socketQueue;
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;
@property(nonatomic, readonly) NSMutableArray <GCDAsyncSocket *> *connectedClients;
@property(nonatomic, strong) NSMutableDictionary *header;//信息头部
@property(nonatomic, copy) NSString *mimePlist;//Plist类型
@property(nonatomic, copy) NSString *mimeoctet;//数据流类型
@property(nonatomic, strong) NSData *appleFairPlayDRM;//Apple FairPlay DRM 加密
@property(nonatomic, weak) id<YKAirPlayRTSPServerDelegate> delegate;
@end

@interface YKAirPlayRTSPServer(AsyncSocket) <GCDAsyncSocketDelegate>
@end

@implementation YKAirPlayRTSPServer

#pragma mark - 初始化
-(instancetype)initWithDelegate:(id<YKAirPlayRTSPServerDelegate>)delegate
{
    self = [super init];
    if (self) {
        
        _delegate = delegate;
        
        _header = [[NSMutableDictionary alloc] init];
        _socketQueue = dispatch_queue_create("com.sky.yk.rtsp.socket", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _connectedClients = [[NSMutableArray alloc] init];
        
        _mimePlist = @"application/x-apple-binary-plist";
        _mimeoctet = @"application/octet-stream";
    }
    return self;
}


#pragma mark - 开始连接
-(int)startWithError:(NSError *__autoreleasing  _Nullable *)error {
    
    /// 禁用IPV6
    [self.listeningSocket setIPv6Enabled:NO];
    
    if (![self.listeningSocket acceptOnPort:0 error:error]) {
        return -1;
    }
    return self.listeningSocket.localPort;
}

#pragma mark - 端口
-(int)port {
    return _listeningSocket.localPort;
}

#pragma mark - 停止
-(void)stop {
    
    @synchronized(self.connectedClients)
    {
        for (NSUInteger i = 0; i < [self.connectedClients count]; i++)
        {
            [[self.connectedClients objectAtIndex:i] disconnect];
        }
    }
}

#pragma mark - 处理信息头部
-(void)handleHeader:(NSDictionary *)header socket:(GCDAsyncSocket *)socket {
    
    //LOGI(@"处理请求头数据%@", header);
    if ([header.allKeys containsObject:@"GET"])
    {
        //是否存在GET请求
        NSString *method = header[@"GET"];
        if ([method isEqualToString:@"/info"]) {
            
            // info 会进来两次第一次是有内容数据,第二次数据内容不会有东西。
            if ([header.allKeys containsObject:@"Content-Length"]) {
                
                int contentLength = [header[@"Content-Length"] intValue];
                [socket readDataToLength:contentLength withTimeout:-1 tag:102];
            } else {
                [self handleInfoRequest:nil socket:socket];
            }
        }
    } else if ([header.allKeys containsObject:@"POST"])
    {
        NSString *method = header[@"POST"];
        int contentLength = [header[@"Content-Length"] intValue];
        if ([method isEqualToString:@"/pair-setup"])
        {
            [socket readDataToLength:contentLength withTimeout:-1 tag:103];
        } else if ([method isEqualToString:@"/pair-verify"])
        {
            [socket readDataToLength:contentLength withTimeout:-1 tag:104];
        } else if ([method isEqualToString:@"/fp-setup"])
        {
            [socket readDataToLength:contentLength withTimeout:-1 tag:105];
        } else if ([method isEqualToString:@"/feedback"])
        {
            // 心跳
            [self sendData:[[NSData alloc]init] CSeq:[self.header[@"CSeq"] intValue] mime:@"" socket:socket];
        }
    } else if ([header.allKeys containsObject:@"SETUP"]) {
        
        int contentLength = [header[@"Content-Length"] intValue];
        [socket readDataToLength:contentLength withTimeout:-1 tag:106];
    } else if ([header.allKeys containsObject:@"GET_PARAMETER"])
    {
        int contentLength = [header[@"Content-Length"] intValue];
        [socket readDataToLength:contentLength withTimeout:-1 tag:107];
    } else if ([header.allKeys containsObject:@"RECORD"])
    {
        [self handleRECORD:socket];
    } else if ([header.allKeys containsObject:@"SET_PARAMETER"])
    {
        int contentLength = [header[@"Content-Length"] intValue];
        [socket readDataToLength:contentLength withTimeout:-1 tag:108];
    } else if ([header.allKeys containsObject:@"TEARDOWN"])
    {
        int contentLength = [header[@"Content-Length"] intValue];
        [socket readDataToLength:contentLength withTimeout:-1 tag:109];
    } else {
        
        LOGI(@"收到心跳请求直接回执空数据");
        [self sendData:[[NSData alloc]init] CSeq:[self.header[@"CSeq"] intValue] mime:@"" socket:socket];
        
    }
}

#pragma mark - 处理 info 请求 回执
-(void)handleInfoRequest:(NSData *)data  socket:(GCDAsyncSocket *)socket {
    
    //验证通过，开始准备给响应值
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    result[@"deviceID"] = @"01:25:3D:A3:01:50";
    result[@"macAddress"] = @"01:25:3D:A3:01:50";
    result[@"features"] = @(0x1E5A7FFFF7);
    result[@"keepAliveLowPower"] = @(1);
    result[@"keepAliveSendStatsAsBody"] = @(1);
    result[@"model"] = @"AppleTV3,2";
    result[@"name"] = @"AppleTV";
    result[@"vv"] = @(2);
    result[@"pk"] = @"13d18e46fcd95587a70c9bd6e4a64a593c789cdd14c0ec8318d2651b43290eaa";
    result[@"pi"] = @"b08f5a79-1b29-4384-b456-a4784d9e6055";
    result[@"sourceVersion"] = @"220.68";
    result[@"statusFlags"] = @(4);
    
    // 设置音频格式等
    NSMutableDictionary *audioItem1 = [[NSMutableDictionary alloc] init];
    audioItem1[@"audioOutputFormats"] = @(67108860);
    audioItem1[@"audioInputFormats"] = @(67108860);
    audioItem1[@"type"] = @(100);
    
    NSMutableDictionary *audioItem2 = [[NSMutableDictionary alloc] init];
    audioItem2[@"audioOutputFormats"] = @(67108860);
    audioItem2[@"audioInputFormats"] = @(67108860);
    audioItem2[@"type"] = @(101);
    result[@"audioFormats"] = @[audioItem1, audioItem2];
    
    // 设置音频延迟
    NSMutableDictionary *audioLatencies1 = [[NSMutableDictionary alloc] init];
    audioLatencies1[@"audioType"] = @"default";
    audioLatencies1[@"inputLatencyMicros"] = @(0);
    audioLatencies1[@"type"] = @(100);
    
    NSMutableDictionary *audioLatencies2 = [[NSMutableDictionary alloc] init];
    audioLatencies2[@"audioType"] = @"default";
    audioLatencies2[@"inputLatencyMicros"] = @(0);
    audioLatencies2[@"type"] = @(101);
    result[@"audioLatencies"] = @[audioLatencies1, audioLatencies2];
    
    // 设置显示信息
    int nWidth = 1080;
    int nHeight = 1920;
    
    
    int nMaxFps = 30;
    NSMutableDictionary *displays = [[NSMutableDictionary alloc]init];
    displays[@"width"] = @(nWidth);
    displays[@"height"] = @(nHeight);
    displays[@"rotation"] = @(false);
    displays[@"widthPhysical"] = @(false);
    displays[@"heightPhysical"] = @(false);
    displays[@"widthPixels"] = @(nWidth);
    displays[@"heightPixels"] = @(nHeight);
    displays[@"refreshRate"] = @(60);
    displays[@"features"] = @(14);
    displays[@"maxFPS"] = @(nMaxFps);
    displays[@"overscanned"] = @(false);
    displays[@"uuid"] = @"e0ff8a27-6738-3d56-8a16-cc53aacee925";
    result[@"displays"] = @[displays];
    
    
    // 将字典转换为二进制格式的NSData
    NSData * binaryData = [YKServiceTool plistDataFromDictionary:result];
    [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimePlist socket:socket];
}

#pragma mark - 处理 pair-setup
-(void)handlePairSetup:(NSData *)data socket:(GCDAsyncSocket *)socket {
    
    NSData * binaryData = [_delegate airPlayRTSPServerGetPairSetupPublicKey];
    [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimeoctet socket:socket];
}

#pragma mark - 处理 pair Verify
-(void)handlePairVerify:(NSData *)data socket:(GCDAsyncSocket *)socket {
    
    const unsigned char *bytes = data.bytes;
    NSData *temData = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
    if (bytes[0] == 1) {
        
        LOGI(@"✅ 验签pairVerify 步骤1");
        NSData *binaryData = [_delegate airPlayRTSPServer:self pairVerifySign1:temData];
        [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimeoctet socket:socket];
    } else {
        
        BOOL result = [_delegate airPlayRTSPServer:self pairVerifySign2:temData];
        if (result) {
            LOGI(@"✅ 验签pairVerify 步骤2 正确");
        } else {
            LOGI(@"❌ 验签pairVerify 步骤2 失败");
        }
        [self sendData:[[NSData alloc] init] CSeq:[self.header[@"CSeq"] intValue] mime:_mimeoctet socket:socket];
    }
}

#pragma mark - 处理 fp-setup
-(void)handleFPSetup:(NSData *)data socket:(GCDAsyncSocket *)socket {
    
    if (data.length == 16)
    {
        const unsigned char *bytes = data.bytes;
        if (bytes[4] != 0x03)
        {
            
            LOGI(@"不支持%s", bytes);
            return;
        }
        
        int mode = bytes[14];
        if (mode > 3) {
            
            LOGI(@"不支持%d", mode);
            return;
        }
        
        static const unsigned char reply_message[4][142] = {
            {'F','P','L','Y',0x03,0x01,0x02,0x00,0x00,0x00,0x00,0x82,0x02,0x00,0x0f,0x9f,0x3f,0x9e,0x0a,0x25,0x21,0xdb,0xdf,0x31,0x2a,0xb2,0xbf,0xb2,0x9e,0x8d,0x23,0x2b,0x63,0x76,0xa8,0xc8,0x18,0x70,0x1d,0x22,0xae,0x93,0xd8,0x27,0x37,0xfe,0xaf,0x9d,0xb4,0xfd,0xf4,0x1c,0x2d,0xba,0x9d,0x1f,0x49,0xca,0xaa,0xbf,0x65,0x91,0xac,0x1f,0x7b,0xc6,0xf7,0xe0,0x66,0x3d,0x21,0xaf,0xe0,0x15,0x65,0x95,0x3e,0xab,0x81,0xf4,0x18,0xce,0xed,0x09,0x5a,0xdb,0x7c,0x3d,0x0e,0x25,0x49,0x09,0xa7,0x98,0x31,0xd4,0x9c,0x39,0x82,0x97,0x34,0x34,0xfa,0xcb,0x42,0xc6,0x3a,0x1c,0xd9,0x11,0xa6,0xfe,0x94,0x1a,0x8a,0x6d,0x4a,0x74,0x3b,0x46,0xc3,0xa7,0x64,0x9e,0x44,0xc7,0x89,0x55,0xe4,0x9d,0x81,0x55,0x00,0x95,0x49,0xc4,0xe2,0xf7,0xa3,0xf6,0xd5,0xba},
            {'F','P','L','Y',0x03,0x01,0x02,0x00,0x00,0x00,0x00,0x82,0x02,0x01,0xcf,0x32,0xa2,0x57,0x14,0xb2,0x52,0x4f,0x8a,0xa0,0xad,0x7a,0xf1,0x64,0xe3,0x7b,0xcf,0x44,0x24,0xe2,0x00,0x04,0x7e,0xfc,0x0a,0xd6,0x7a,0xfc,0xd9,0x5d,0xed,0x1c,0x27,0x30,0xbb,0x59,0x1b,0x96,0x2e,0xd6,0x3a,0x9c,0x4d,0xed,0x88,0xba,0x8f,0xc7,0x8d,0xe6,0x4d,0x91,0xcc,0xfd,0x5c,0x7b,0x56,0xda,0x88,0xe3,0x1f,0x5c,0xce,0xaf,0xc7,0x43,0x19,0x95,0xa0,0x16,0x65,0xa5,0x4e,0x19,0x39,0xd2,0x5b,0x94,0xdb,0x64,0xb9,0xe4,0x5d,0x8d,0x06,0x3e,0x1e,0x6a,0xf0,0x7e,0x96,0x56,0x16,0x2b,0x0e,0xfa,0x40,0x42,0x75,0xea,0x5a,0x44,0xd9,0x59,0x1c,0x72,0x56,0xb9,0xfb,0xe6,0x51,0x38,0x98,0xb8,0x02,0x27,0x72,0x19,0x88,0x57,0x16,0x50,0x94,0x2a,0xd9,0x46,0x68,0x8a},
            {'F','P','L','Y',0x03,0x01,0x02,0x00,0x00,0x00,0x00,0x82,0x02,0x02,0xc1,0x69,0xa3,0x52,0xee,0xed,0x35,0xb1,0x8c,0xdd,0x9c,0x58,0xd6,0x4f,0x16,0xc1,0x51,0x9a,0x89,0xeb,0x53,0x17,0xbd,0x0d,0x43,0x36,0xcd,0x68,0xf6,0x38,0xff,0x9d,0x01,0x6a,0x5b,0x52,0xb7,0xfa,0x92,0x16,0xb2,0xb6,0x54,0x82,0xc7,0x84,0x44,0x11,0x81,0x21,0xa2,0xc7,0xfe,0xd8,0x3d,0xb7,0x11,0x9e,0x91,0x82,0xaa,0xd7,0xd1,0x8c,0x70,0x63,0xe2,0xa4,0x57,0x55,0x59,0x10,0xaf,0x9e,0x0e,0xfc,0x76,0x34,0x7d,0x16,0x40,0x43,0x80,0x7f,0x58,0x1e,0xe4,0xfb,0xe4,0x2c,0xa9,0xde,0xdc,0x1b,0x5e,0xb2,0xa3,0xaa,0x3d,0x2e,0xcd,0x59,0xe7,0xee,0xe7,0x0b,0x36,0x29,0xf2,0x2a,0xfd,0x16,0x1d,0x87,0x73,0x53,0xdd,0xb9,0x9a,0xdc,0x8e,0x07,0x00,0x6e,0x56,0xf8,0x50,0xce},
            {'F','P','L','Y',0x03,0x01,0x02,0x00,0x00,0x00,0x00,0x82,0x02,0x03,0x90,0x01,0xe1,0x72,0x7e,0x0f,0x57,0xf9,0xf5,0x88,0x0d,0xb1,0x04,0xa6,0x25,0x7a,0x23,0xf5,0xcf,0xff,0x1a,0xbb,0xe1,0xe9,0x30,0x45,0x25,0x1a,0xfb,0x97,0xeb,0x9f,0xc0,0x01,0x1e,0xbe,0x0f,0x3a,0x81,0xdf,0x5b,0x69,0x1d,0x76,0xac,0xb2,0xf7,0xa5,0xc7,0x08,0xe3,0xd3,0x28,0xf5,0x6b,0xb3,0x9d,0xbd,0xe5,0xf2,0x9c,0x8a,0x17,0xf4,0x81,0x48,0x7e,0x3a,0xe8,0x63,0xc6,0x78,0x32,0x54,0x22,0xe6,0xf7,0x8e,0x16,0x6d,0x18,0xaa,0x7f,0xd6,0x36,0x25,0x8b,0xce,0x28,0x72,0x6f,0x66,0x1f,0x73,0x88,0x93,0xce,0x44,0x31,0x1e,0x4b,0xe6,0xc0,0x53,0x51,0x93,0xe5,0xef,0x72,0xe8,0x68,0x62,0x33,0x72,0x9c,0x22,0x7d,0x82,0x0c,0x99,0x94,0x45,0xd8,0x92,0x46,0xc8,0xc3,0x59}
        };
        
        NSData *binaryData = [[NSData alloc] initWithBytes:reply_message[mode] length:142];
        [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimeoctet socket:socket];
        
    }
    else if (data.length == 164)
    {
        const unsigned char *bytes = data.bytes;
        if (bytes[4] != 0x03)
        {
            
            LOGI(@"不支持%s", bytes);
            return;
        }
        
        self.appleFairPlayDRM = data;
        static const char fpHeader[12] = { 'F','P','L','Y', 0x03, 0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x14 };
        NSMutableData *binaryData = [[NSMutableData alloc] init];
        [binaryData appendData:[[NSData alloc] initWithBytes:fpHeader length:12]];
        [binaryData appendData:[data subdataWithRange:NSMakeRange(data.length - 20, 20)]];
        [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimeoctet socket:socket];
    }
    
}

#pragma mark - 处理 SETUP
-(void)handleSETUP:(NSData *)data socket:(GCDAsyncSocket *)socket {
        
    NSError *error = nil;
    NSDictionary *plistDict = [NSPropertyListSerialization propertyListWithData:data
                                                                        options:NSPropertyListImmutable
                                                                         format:nil
                                                                          error:&error];
    LOGI(@"输出数据SETUP %@",plistDict);
    if (error) {
        LOGI(@"❌ 解析失败 %@", error.localizedDescription);
        return;
    }
    
    NSData *eiv = plistDict[@"eiv"];
    NSData *ekey = plistDict[@"ekey"];
    NSArray *streams = plistDict[@"streams"];
    if (eiv && ekey)
    {
        LOGI(@"SETUP-1");
        [_delegate airPlayRTSPServer:self appleFairPlayDRM:self.appleFairPlayDRM ekey:ekey];
        NSDictionary *resut = @{@"timingPort": @(self.port)};
        
        NSData * binaryData = [YKServiceTool plistDataFromDictionary:resut];
        [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimePlist socket:socket];
    } else if (streams) {
        
        LOGI(@"SETUP-2");
        
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *subResult = [[NSMutableDictionary alloc] init];
        
        result[@"eventPort"] = @(self.port);
        result[@"timingPort"] = @(self.port);
        for (NSDictionary *item in streams.objectEnumerator)
        {
            int type = [item[@"type"] intValue];
            if (type == 110) {
                
                uint64_t streamConnectionID = [item[@"streamConnectionID"] longLongValue];
                BOOL suc = [_delegate airPlayRTSPServer:self streamConnectionID:streamConnectionID];
                if (suc) {
                    LOGI(@"创建成功镜像Socket");
                    int mirrorPort = [_delegate airPlayRTSPServerGetMirrorPort];
                    subResult[@"dataPort"] = @(mirrorPort);
                    subResult[@"type"] = @(110);
                } else {
                    LOGI(@"解密streamConnectionID 失败或者 镜像Socket 创建失败");
                }
            } else if (type == 96) {
                
                uint64_t streamConnectionID = [item[@"streamConnectionID"] longLongValue];
                BOOL suc = [_delegate airPlayRTSPServer:self streamConnectionID:streamConnectionID];
                if (suc) {
                    NSDictionary * audioPort = [_delegate airPlayRTSPServerGetAudioPort];
                    subResult[@"dataPort"] = audioPort[@"dataPort"];
                    subResult[@"controlPort"] = audioPort[@"controlPort"];
                    subResult[@"type"] = @(96);
                }

            } else {
                LOGI(@"未知类型");
            }
        }
        result[@"streams"] = @[subResult];
        
        NSData * binaryData = [YKServiceTool plistDataFromDictionary:result];
        [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:_mimePlist socket:socket];
    }
}

#pragma mark - 处理 GET_PARAMETER
-(void)handleGETPARAMETER:(NSData *)data socket:(GCDAsyncSocket *)socket {
    
    NSData *binaryData = [@"volume: 0.0\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:binaryData CSeq:[self.header[@"CSeq"] intValue] mime:@"text/parameters" socket:socket];
}

#pragma mark - 处理 RECORD
-(void)handleRECORD:(GCDAsyncSocket *)socket {
    [self sendData:[[NSData alloc] init] CSeq:[self.header[@"CSeq"] intValue] mime:@"" socket:socket];
}

#pragma mark - 处理 SET_PARAMETER
-(void)handleSETPARAMETER:(NSData *)data socket:(GCDAsyncSocket *)socket {
    [self sendData:[[NSData alloc] init] CSeq:[self.header[@"CSeq"] intValue] mime:@"" socket:socket];
}

#pragma mark - 断开的原因
-(void)handleTEARDOWN:(NSData *)data socket:(GCDAsyncSocket *)socket {

//    NSDictionary *plistDict = [NSPropertyListSerialization propertyListWithData:data
//                                                                        options:NSPropertyListImmutable
//                                                                         format:nil
//                                                                          error:nil];
//    LOGI(@"断开了连接原因:%@",plistDict);
    [self stop];//停止上一个Socket的连接
    [_delegate airPlayRTSPServerStop:self];
}

#pragma mark - 发送数据
-(void)sendData:(NSData *)data CSeq:(int)CSeq mime:(NSString *)mime socket:(GCDAsyncSocket *)socket
{
    NSString *response = [self buildResponseHeader:(unsigned long)data.length CSeq:CSeq mime:mime];
    NSMutableData *responseData = [NSMutableData dataWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
    [responseData appendData:data];
    [self.header removeAllObjects];
    [socket writeData:responseData withTimeout:-1 tag:0];
    [socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:101]; // 接着等下一个请求
}

#pragma mark - 构建响应头
-(NSString *)buildResponseHeader:(unsigned long)contentLength CSeq:(int)CSeq mime:(NSString *)mime {
    
    NSMutableString *response = [NSMutableString stringWithFormat:
                                 @"RTSP/1.0 200 OK\r\n"
                                 "Content-Length: %lu\r\n"
                                 "Content-Type: %@\r\n"
                                 "Server: AirTunes/366.0\r\n"
                                 "CSeq: %d\r\n\r\n", contentLength, mime, CSeq];
    return response;
}
@end


//============================================================
// Socket回调
//============================================================
@implementation YKAirPlayRTSPServer(AsyncSocket)

#pragma mark - 接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [self.connectedClients addObject:newSocket];
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:101]; // 等待 RTSP 请求
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == 101)
    {
        //请求头部的响应的数据
        NSString *requestString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //LOGI(@"输出响应内容是是什么%@", requestString);
        NSArray *lines = [requestString componentsSeparatedByString:@"\r\n"];
        NSString *requestLine = lines.firstObject;
        NSArray *requestParts = [requestLine componentsSeparatedByString:@" "];
        
        if (requestParts.count < 2) {
            [self handleHeader:self.header socket:sock];
            return;
        }
        
        NSString *method = requestParts[0];
        method = [method stringByReplacingOccurrencesOfString:@":" withString:@""];
        NSString *uri = requestParts[1];
        self.header[method] = uri;
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:101];
    } else if (tag == 102) {
        [self handleInfoRequest:data socket:sock];
    } else if (tag == 103) {
        [self handlePairSetup:data socket:sock];
    } else if (tag == 104) {
        [self handlePairVerify:data socket:sock];
    } else if (tag == 105) {
        [self handleFPSetup:data socket:sock];
    } else if (tag == 106) {
        [self handleSETUP:data socket:sock];
    } else if (tag == 107) {
        [self handleGETPARAMETER:data socket:sock];
    } else if (tag == 108) {
        [self handleSETPARAMETER:data socket:sock];
    } else if (tag == 109) {
        [self handleTEARDOWN:data socket:sock];
    }
}

#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self.connectedClients removeObject:sock];
}
@end



#pragma clang diagnostic pop

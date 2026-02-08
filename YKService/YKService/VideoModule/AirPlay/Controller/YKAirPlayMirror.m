//
//  YKAirPlayMirror.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//

#import "GCDAsyncSocket.h"
#import "YKAirPlayMirror.h"
#import "YKServiceLogger.h"

@interface YKAirPlayMirror()
@property(nonatomic, readonly) dispatch_queue_t socketQueue;
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;
@property(nonatomic, readonly) NSMutableArray <GCDAsyncSocket *> *connectedClients;
@property(nonatomic, readonly) uint16_t port;
@property(nonatomic, assign) int nPayloadType;
@property(nonatomic, weak) id<YKAirPlayMirrorDelegate> delegate;
@end


@interface YKAirPlayMirror(AsyncSocket) <GCDAsyncSocketDelegate>
@end

@implementation YKAirPlayMirror

-(instancetype)initWithDelegate:(id<YKAirPlayMirrorDelegate>)delegate {
    
    self = [super init];
    if (self) {
        
        _delegate = delegate;
        _socketQueue = dispatch_queue_create("com.sky.yk.mirror.socket", NULL);
        dispatch_set_target_queue(_socketQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _connectedClients = [[NSMutableArray alloc] init];
        
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

#pragma mark - 停止
-(void)stop {
    
    @synchronized(self.connectedClients)
    {
        for (NSUInteger i = 0; i < [self.connectedClients count]; i++)
        {
            [[self.connectedClients objectAtIndex:i] disconnect];
        }
    }
    [self.listeningSocket disconnect];
}

@end


//============================================================
// Socket回调
//============================================================
@implementation YKAirPlayMirror(AsyncSocket)

#pragma mark - 接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [self.connectedClients addObject:newSocket];
    [newSocket readDataToLength:128 withTimeout:-1 tag:0];
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == 0) {
        
        uint32_t length;
        [data getBytes:&length range:NSMakeRange(0, 4)];
        
        uint16_t nPayloadType;
        [data getBytes:&nPayloadType range:NSMakeRange(4, 2)];
        
        self.nPayloadType = nPayloadType & 0xff;
        [sock readDataToLength:length withTimeout:-1 tag:1];
        
    } else {

        [_delegate airPlayMirror:self nPayloadType:self.nPayloadType data:data];
        [sock readDataToLength:128 withTimeout:-1 tag:0];
    }
}

#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self.connectedClients removeObject:sock];
}
@end

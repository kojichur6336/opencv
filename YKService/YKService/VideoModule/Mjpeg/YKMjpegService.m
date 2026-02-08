//
//  YKMjpegService.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/25.
//

#import "GCDAsyncSocket.h"
#import "YKMjpegService.h"
#import "YKServiceLogger.h"
#import "YKServiceIOSurface.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const SERVER_NAME = @"YK MJPEG Server";

@interface YKMjpegService()
@property(nonatomic, readonly) dispatch_queue_t socketQueue;
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;
@property(nonatomic, readonly) NSMutableArray *connectedClients;
@property(nonatomic, readonly) dispatch_queue_t backgroundQueue;
@property(nonatomic, readonly) NSMutableArray<GCDAsyncSocket *> *listeningClients;
@property(nonatomic, strong) CADisplayLink *displayLink;
@end

@interface YKMjpegService(AsyncSocket) <GCDAsyncSocketDelegate>

@end

@implementation YKMjpegService

-(instancetype)init {
    
    if ((self = [super init]))
    {
        _socketQueue = dispatch_queue_create("socketQueue", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _connectedClients = [[NSMutableArray alloc] initWithCapacity:1];
        _listeningClients = [NSMutableArray array];
        
        _backgroundQueue = dispatch_queue_create("com.sky.mjpeg.queue", DISPATCH_QUEUE_SERIAL);
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink)];
        _displayLink.preferredFramesPerSecond = 30;
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
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
        return NO;;
    }
    LOGI(@"Mjpeg端口:%d", self.port);
    return YES;
}

#pragma mark - 停止监听
-(void)stop
{
    @synchronized(self.listeningClients)
    {
        for (NSUInteger i = 0; i < [self.listeningClients count]; i++)
        {
            [[self.listeningClients objectAtIndex:i] disconnect];
        }
    }
    [self.listeningSocket disconnect];
}

#pragma mark - 本地端口
-(UInt16)port {
    return _listeningSocket.localPort;
}

#pragma mark - 屏幕刷新率
-(void)handleDisplayLink {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_async(self.backgroundQueue, ^{
        
        @autoreleasepool {
            NSData *screenshotData = YKScreenShotMjpeg(1,1.0);
            if (screenshotData) {
                NSString *chunkHeader = [NSString stringWithFormat:@"--BoundaryString\r\nContent-type: image/jpeg\r\nContent-Length: %@\r\n\r\n", @(screenshotData.length)];
                NSMutableData *chunk = [[chunkHeader dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
                [chunk appendData:screenshotData];
                [chunk appendData:(id)[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                @synchronized (self.listeningClients) {
                    for (GCDAsyncSocket *client in self.listeningClients)
                    {
                        [client writeData:chunk withTimeout:-1 tag:0];
                    }
                }
            }
        }
    });
}
@end

//============================================================
// GCDAsyncSocketDelegate
//============================================================
@implementation YKMjpegService(AsyncSocket)

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    @synchronized(self.connectedClients) {
        [self.connectedClients addObject:newSocket];
    }
    [newSocket readDataWithTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    @synchronized (self.listeningClients) {
      if ([self.listeningClients containsObject:sock]) {
        return;
      }
    }
    NSString *streamHeader = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nServer: %@\r\nConnection: close\r\nMax-Age: 0\r\nExpires: 0\r\nCache-Control: no-cache, private\r\nPragma: no-cache\r\nContent-Type: multipart/x-mixed-replace; boundary=--BoundaryString\r\n\r\n", SERVER_NAME];
    [sock writeData:(id)[streamHeader dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    self.displayLink.paused = NO;
    @synchronized (self.listeningClients) {
      [self.listeningClients addObject:sock];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    @synchronized(self.connectedClients) {
        [self.connectedClients removeObject:sock];
    }
    
    @synchronized (self.listeningClients) {
      [self.listeningClients removeObject:sock];
    }
    self.displayLink.paused = YES;
}

@end

//
//  YKNativeWebSocket.m
//  Created on 2025/11/30
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKWebSocket.h"
#import "YKServiceLogger.h"

@interface YKWebSocket()<NSURLSessionDelegate, NSURLSessionWebSocketDelegate>
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) NSURLSessionWebSocketTask *socket;
@property(nonatomic, strong) NSURLSession *urlSession;
@property(nonatomic, strong) NSTimer *heartbeatTimer;
@property(nonatomic, assign) BOOL shouldReconnect;      // 自动重连标记
@property(nonatomic, assign) NSInteger retryCount;      // 重连次数计数
@end

@implementation YKWebSocket

#pragma mark - 初始化
-(instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        
        _shouldReconnect = YES;
        _retryCount = 0;
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - 连接
-(void)connect {
    
    if (self.socket != nil) return; // 防止重复连接
    
    self.shouldReconnect = YES;
    
    self.socket = [self.urlSession webSocketTaskWithURL:self.url];
    [self.socket resume];
    [self listen];
}

#pragma mark - 发送数据
-(void)sendData:(NSData *)data {
    
    if (!self.socket) return;
    
    [self.socket sendMessage:[[NSURLSessionWebSocketMessage alloc] initWithData:data] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            LOGI(@"发送数据失败%@", error);
        }
    }];
}

#pragma mark - 发送文本数据
-(void)sendText:(NSString *)text {
    
    if (!self.socket) return;
    
    [self.socket sendMessage:[[NSURLSessionWebSocketMessage alloc] initWithString:text]
           completionHandler:^(NSError * _Nullable error) {
        if (error) {
            LOGI(@"发送数据失败 %@", error);
        }
    }];
}

#pragma mark - 监听数据
-(void)listen {
    
    [self.socket receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        
        if (error) {
            [self disconnect];
            return;
        }
        
        if (message.type == NSURLSessionWebSocketMessageTypeData) {
            [self.delegate webSocket:self didReceiveData:message.data];
        } else {
            [self.delegate webSocket:self didReceiveText:message.string];
        }
        [self listen];
    }];
}


#pragma mark - 心跳 Ping
-(void)startHeartbeat {
    
    [self stopHeartbeat];
    
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                           target:self
                                                         selector:@selector(sendPing)
                                                         userInfo:nil
                                                          repeats:YES];
}

#pragma mark - 停止心跳
-(void)stopHeartbeat {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}


#pragma mark - 发送Ping
-(void)sendPing {
    
    if (!self.socket) return;
    
    LOGI(@"WebSocket 🔄 Ping");
    __weak typeof(self) weakSelf = self;
    [self.socket sendPingWithPongReceiveHandler:^(NSError * _Nullable error) {
        if (error) {
            LOGI(@"WebSocket ❌ Pong 超时 %@", error);
            [weakSelf handleDisconnectWithError:error];
        } else {
            LOGI(@"WebSocket ✅ Pong OK");
        }
    }];
}


#pragma mark - 断开连接
-(void)disconnect {
    
    self.shouldReconnect = NO;          // 主动断开不再重连
    self.retryCount = 0;
    
    [self stopHeartbeat];
    
    if (self.socket) {
        [self.socket cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
        self.socket = nil;
    }
    
    [self.delegate webSocketDidDisconnect:self];
}


#pragma mark - 自动重连与错误处理
-(void)handleDisconnectWithError:(NSError *)error {

    [self stopHeartbeat];

    if (self.socket) {
        [self.socket cancel];
        self.socket = nil;
    }

    if (!self.shouldReconnect) return;

    self.retryCount++;

    // 间隔 2 秒重连（可调整）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        LOGI(@"WebSocket 尝试重连… 第 %ld 次", (long)self.retryCount);
        [self connect];
    });
}


#pragma mark - URLSessionWebSocketDelegate
-(void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(nullable NSString *)protocol {
    if ([self.delegate respondsToSelector:@selector(webSocketDidConnect:)]) {
        [self.delegate webSocketDidConnect:self];
    }
}

-(void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason
{
    [self disconnect];
}
@end

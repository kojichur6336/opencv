//
//  YKFileUploadSocket.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//


#import "YKConstants.h"
#import "YKServiceLogger.h"
#import "YKFileUploadSocket.h"
#import "YKFileReaderManager.h"
#import <YKSocket/GCDAsyncSocket.h>

@interface YKFileUploadSocket()
@property(readonly, nonatomic) dispatch_queue_t socketQueue;
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;//USB 监听
@property(nonatomic, strong) GCDAsyncSocket *clientSocket;//连接者
@property(nonatomic, strong) YKFileReaderManager *fileReaderManager;//文件读取管理类
@property(nonatomic, assign) BOOL isUploadFinished;// 是否上传完成
@property(nonatomic, assign) BOOL isUSB;//是否是USB
@property(nonatomic, assign) int chunkSize;//文件每次上传大小
@property(nonatomic, copy) void (^completion)(BOOL success, NSString *msg);
@property(nonatomic, copy) void (^portCallback)(UInt16 port);
@end

@interface YKFileUploadSocket(AsyncSocket) <GCDAsyncSocketDelegate>
@end


@implementation YKFileUploadSocket

#pragma mark - 初始化
-(instancetype)initWithModel:(YKFileUploadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(nonnull void (^)(BOOL, NSString * _Nonnull))completion
{
    self = [super init];
    if (self) {
        
        _model = model;
        _portCallback = portCallback;
        _completion = completion;
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSString *queueName = [NSString stringWithFormat:@"com.sky.yk.fileUpload.%@", uuid];
        _socketQueue = dispatch_queue_create([queueName UTF8String], NULL);
        if ([model.ip isEqualToString:YK_USB_LOCALHOST]) {
            _isUSB = YES;
            _chunkSize = YK_FILE_CHUNKSIZE;
            _listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        } else {
            _isUSB = NO;
            _chunkSize = YK_FILE_CHUNKSIZE;
            _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        }
    }
    return self;
}

#pragma mark - 开始
-(void)start {
    
    NSError *error;
    _fileReaderManager = [[YKFileReaderManager alloc] initWithFilePath:_model.path chunkSize:_chunkSize error:&error];
    if (error) {
        _completion(NO, error.localizedDescription);
        return;
    }
    
    _model.totalFileSize = _fileReaderManager.totalSize;
    
    
    if (_isUSB) {
        
        // 禁用IPV6
        [_listeningSocket setIPv6Enabled:NO];
        
        // 动态尝试端口
        [self startListening];
        
    } else {
        
        // 这边目前只写了WIFI
        BOOL result =  [_clientSocket connectToHost:_model.ip onPort:_model.port withTimeout:5 error:&error];
        if (!result) {
            self.completion(NO, error.localizedDescription);
        }
    }
}


#pragma mark - USB端口监听
-(void)startListening {
    
    NSError *error = nil;
    BOOL result = [_listeningSocket acceptOnPort:0 error:&error];
    if (result) {
        self.portCallback(self.listeningSocket.localPort);
    }
}

#pragma mark - 停止
-(void)stop {
    
    if (_clientSocket.isConnected) {
        [_clientSocket disconnect];
    }
}


#pragma mark - 发送下一块
-(void)sendNextChunk {

    if ([self.fileReaderManager hasMoreData])
    {
        NSData *chunk = [_fileReaderManager readNextChunk];
        if (chunk) {
            //30秒内发送数据就认为是超时。直接断开
            _model.totalBytesSent += chunk.length;
            [self.clientSocket writeData:chunk withTimeout:30 tag:2];
            [self sendNextChunk];
        } else {
            [self stop];
            [self.fileReaderManager close];
            _completion(NO, @"文件数据读取异常");
        }
    } else {
        
        [self.fileReaderManager close];
        [_clientSocket readDataWithTimeout:-1 tag:0];
    }
}

#pragma mark - 发送数据大小
-(void)sentDataSize {
    
    uint64_t fileSize = self.fileReaderManager.totalSize;
    NSData *headerData = [NSData dataWithBytes:&fileSize length:8];
    [self.clientSocket writeData:headerData withTimeout:30 tag:1];
    [self sendNextChunk];
}


#pragma mark - 释放
-(void)dealloc {
    
    LOGI(@"释放了文件上传的类");
    if (_listeningSocket) {
        [_listeningSocket disconnect];
    }
}
@end


//============================================================
// Socket回调
//============================================================
@implementation YKFileUploadSocket(AsyncSocket)

#pragma mark - USB接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSString *ip = [newSocket connectedHost];
    if ([ip isEqualToString:YK_USB_LOCALHOST])
    {
        _clientSocket = newSocket;
        [self sentDataSize];
    }
}

#pragma mark - WIFI连接成功回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    [self sentDataSize];
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //do thing
}

#pragma mark - 写入数据成功后回调
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    
}

#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (_isUSB) {
        _listeningSocket.delegate = nil;
        [_listeningSocket disconnect];//断开自己
    }
    
    if (err.code == GCDAsyncSocketClosedError)
    {
        LOGI(@"文件上传正常断开");
        //正常断开
        _completion(YES, @"上传成功");
    } else {
        
        LOGI(@"文件上传异常断开");
        _completion(NO, err.localizedDescription);
    }
}
@end

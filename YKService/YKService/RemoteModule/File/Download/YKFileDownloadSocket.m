//
//  YKFileDownloadSocket.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/28.
//

#import "YKConstants.h"
#import "YKServiceLogger.h"
#import "YKFileWriteManager.h"
#import "YKFileDownloadSocket.h"
#import <YKSocket/GCDAsyncSocket.h>

@interface YKFileDownloadSocket()
@property(readonly, nonatomic) dispatch_queue_t socketQueue;
@property(nonatomic, strong) YKFileWriteManager *fileWriteManager;//文件写入管理类
@property(nonatomic, readonly) GCDAsyncSocket *listeningSocket;//USB 监听
@property(nonatomic, strong) GCDAsyncSocket *clientSocket;//连接者
@property(nonatomic, assign) BOOL isUSB;//是否是USB
@property(nonatomic, assign) int chunkSize;//文件每次上传大小
@property(nonatomic, copy) void (^completion)(BOOL success, NSString *msg);
@property(nonatomic, copy) void (^portCallback)(UInt16 port);

@property(nonatomic, copy) NSString *duofa;

@end

@interface YKFileDownloadSocket(AsyncSocket) <GCDAsyncSocketDelegate>
@end

@implementation YKFileDownloadSocket

-(instancetype)initWithModel:(YKFileDownloadModel *)model portCallback:(void (^)(UInt16))portCallback completion:(void (^)(BOOL success, NSString *msg))completion
{
    self = [super init];
    if (self) {
        
        _model = model;
        _portCallback = portCallback;
        _completion = completion;
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSString *queueName = [NSString stringWithFormat:@"com.sky.yk.fileDownload.%@", uuid];
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
    
    // 检查存储空间
    if (![self checkFreeSpaceForFileSize:self.model.totalFileSize])
    {
        self.completion(NO, @"手机存储空间不足，无法下载文件");
        return;
    }
    
    
    NSError *error;
    _fileWriteManager = [[YKFileWriteManager alloc] initWithFilePath:self.model.path error:&error];
    
    if (error) {
        self.completion(NO, error.localizedDescription);
        return;
    }
    
    if (_isUSB) {
        
        // 禁用IPV6
        [_listeningSocket setIPv6Enabled:NO];
        
        // 动态尝试端口
        [self startListening];
        
    } else {
        
        
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
        // 成功监听端口，回调通知PC使用该端口
        self.portCallback(self.listeningSocket.localPort);
    }
}

#pragma mark - 停止
-(void)stop {
    
    if (_clientSocket.isConnected) {
        [_clientSocket disconnect];
    }
}

#pragma mark - 下载下一块
-(void)downLoadNextChunk {
    
    //如果是下载的话就是每次
    NSUInteger chunkSize = _chunkSize;
    long long int bytesRemaining = _model.totalFileSize - _model.totalBytesReceived;
    NSUInteger bytesToRead = MIN(chunkSize, bytesRemaining);
    
    if (bytesToRead <= 0)
    {
        [self.fileWriteManager close];
        [self.clientSocket readDataWithTimeout:-1 tag:0];//USB下断开还是需要等待收信息
    }
    else
    {
        if (self.clientSocket.isConnected)
        {
            //30秒内没有收到指定的大小数据就认为是超时。直接断开
            [self.clientSocket readDataToLength:bytesToRead withTimeout:30 tag:1];
        }
    }
}

#pragma mark - 验证手机容量
-(BOOL)checkFreeSpaceForFileSize:(unsigned long long)fileSize
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    unsigned long long freeSpace = [attrs[NSFileSystemFreeSize] unsignedLongLongValue];
    
    if (fileSize > freeSpace) {
        return NO;
    }
    return YES;
}

#pragma mark - 释放
-(void)dealloc {
    
    LOGI(@"释放了文件下载的类");
    if (_listeningSocket) {
        [_listeningSocket disconnect];
    }
}
@end


//============================================================
// Socket回调
//============================================================
@implementation YKFileDownloadSocket(AsyncSocket)

#pragma mark - USB接受到一个新的连接时调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSString *ip = [newSocket connectedHost];
    if ([ip isEqualToString:YK_USB_LOCALHOST])
    {
        _clientSocket = newSocket;
        [self downLoadNextChunk];
    }
}

#pragma mark - WIFI连接成功回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    [self downLoadNextChunk];
}

#pragma mark - 读取到数据时调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    YKFileDownloadModel *model = self.model;
    model.totalBytesReceived += data.length;
    [self.fileWriteManager writeData:data];
    
    uint64_t received = (uint64_t)model.totalBytesReceived;
    NSData *ackData = [NSData dataWithBytes:&received length:sizeof(received)];
    [sock writeData:ackData withTimeout:-1 tag:10];
    [self downLoadNextChunk];
}


#pragma mark - 当有Socket端开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (_isUSB) {
        _listeningSocket.delegate = nil;
        [_listeningSocket disconnect];//断开自己
    }
    
    if (err.code == GCDAsyncSocketClosedError || err.code == GCDAsyncSocketNoError)
    {
        if (_model.totalBytesReceived != _model.totalFileSize)
        {
            LOGI(@"数据量不匹配,远程就断开连接,文件大小 = %lld, 已接收大小 = %lld", _model.totalFileSize, _model.totalBytesReceived);
            NSString *msg = [NSString stringWithFormat:@"数据量不匹配,远程就断开连接,文件大小 = %lld, 已接收大小 = %lld", _model.totalFileSize, _model.totalBytesReceived];
            [self.fileWriteManager fail];
            _completion(NO, msg);
        } else {
            //正常断开
            LOGI(@"文件下载正常断开");
            _completion(YES, @"下载成功");
        }
    } else {
        
        LOGI(@"文件下载异常断开%d",err.code);
        [self.fileWriteManager fail];
        if (err.code == 0) {
            _completion(NO, @"异常断开");
        } else {
            _completion(NO, err.localizedDescription);
        }
    }
}
@end

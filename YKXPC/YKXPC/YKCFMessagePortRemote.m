//
//  YKCFMessagePortRemote.m
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import "YKXPCLogger.h"
#import "YKCFMessagePortRemote.h"

@implementation YKCFMessagePortSyncResult

+ (instancetype)resultWithError:(YKCFMessagePortErrorCode)errorCode reply:(NSDictionary *)reply {
    YKCFMessagePortSyncResult *result = [YKCFMessagePortSyncResult new];
    result.errorCode = errorCode;
    result.replyData = reply;
    return result;
}
@end

@interface YKCFMessagePortRemote () {
    CFMessagePortRef _remotePort;      // 远程 CFMessagePort 实例（客户端）
    dispatch_queue_t _queue;            // 发送消息的串行队列，保证线程安全
    NSString *_portName;                // 端口名称
}
@end


@implementation YKCFMessagePortRemote


/// 内联函数，NSDictionary 转 NSData（JSON序列化）
/// @param dict 字典对象
static inline NSData * _Nullable YKCFMessagePortSerializeDictionary(NSDictionary *dict) {
    if (!dict) {
        return nil;
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error) {
        LOGI(@"远程端口 JSON序列化 失败: %@", error);
        return nil;
    }
    return data;
}

/// 内联函数，NSData 转 NSDictionary（JSON反序列化）
/// @param data 数据对象
static inline NSDictionary * _Nullable YKCFMessagePortDeserializeData(NSData *data) {
    if (!data) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        LOGI(@"远程端口 JSON反序列化 失败: %@", error);
        return nil;
    }
    return dict;
}


#pragma mark - 初始化
-(instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _portName = [name copy];
        // 创建串行队列，确保多线程发送消息安全
        _queue = dispatch_queue_create("com.sky.yk.cfmessageport.remote.queue", DISPATCH_QUEUE_SERIAL);
        
        if (![self _createRemotePortIfNeeded]) {
            //LOGI(@"初始化时创建远程端口失败");
            return nil;
        }
        
        // 默认超时可以设个值
        _sendTimeout = 1.0;
        _rcvTimeout = 1.0;
    }
    return self;
}

#pragma mark - 发送消息
-(YKCFMessagePortErrorCode)sendMessage:(NSInteger)cmd {
    return [self sendMessage:@{} cmd:cmd maxRetries:1];
}

-(YKCFMessagePortErrorCode)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd
{
    return [self sendMessage:message cmd:cmd maxRetries:1];
}

-(YKCFMessagePortErrorCode)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd maxRetries:(NSUInteger)retryCount
{
    
    if (![self _createRemotePortIfNeeded]) {
        return YKCFMessagePortErrorRemotePortUnavailable;
    }
    
    NSData *data = YKCFMessagePortSerializeDictionary(message);
    if (!data) {
        return YKCFMessagePortErrorSerializeFailed;
    }
    
    __block YKCFMessagePortErrorCode finalError = YKCFMessagePortErrorUnknown;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(_queue, ^{
        NSUInteger retries = 0;
        BOOL success = NO;
        SInt32 err = kCFMessagePortSuccess;
        SInt32 msgid = (SInt32)cmd;
        
        while (retries <= retryCount && !success) {
            err = CFMessagePortSendRequest(self->_remotePort,
                                           msgid,
                                           (__bridge CFDataRef)data,
                                           self.sendTimeout,
                                           0.0,
                                           NULL,
                                           NULL);
            
            if (err == kCFMessagePortSuccess) {
                success = YES;
                finalError = YKCFMessagePortErrorSuccess;
            } else {
                if (err == kCFMessagePortIsInvalid) {
                    // 端口失效，重建端口
                    CFRelease(self->_remotePort);
                    self->_remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)self->_portName);
                    if (!self->_remotePort) {
                        finalError = YKCFMessagePortErrorRemotePortUnavailable;
                        break;
                    }
                } else if (err == kCFMessagePortSendTimeout) {
                    finalError = YKCFMessagePortErrorSendTimeout;
                } else {
                    finalError = YKCFMessagePortErrorUnknown;
                }
                
                retries++;
                [NSThread sleepForTimeInterval:0.1];
            }
        }
        dispatch_semaphore_signal(sema);
    });
    
    // 阻塞等待异步发送完成
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return finalError;
}

#pragma mark - 发送消息
-(void)sendMessage:(NSDictionary *)message cmd:(NSInteger)cmd maxRetries:(NSUInteger)retryCount resultHandlerQueue:(dispatch_queue_t)callbackQueue replyHandler:(YKCFMessagePortAsyncReplyHandler)handler
{
    
    NSData *data = YKCFMessagePortSerializeDictionary(message);
    if (!data) {
        if (handler) {
            dispatch_async(callbackQueue ?: dispatch_get_main_queue(), ^{
                handler(nil, YKCFMessagePortErrorSerializeFailed); // 数据序列化失败
            });
        }
        return;
    }
    
    
    dispatch_async(_queue, ^{
        
        // 确保远程端口有效，失败则重建
        if (!self->_remotePort) {
            self->_remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)self->_portName);
            if (!self->_remotePort) {
                if (handler) {
                    dispatch_async(callbackQueue ?: dispatch_get_main_queue(), ^{
                        handler(nil, YKCFMessagePortErrorRemotePortUnavailable);
                    });
                }
                return;
            }
        }
        
        
        __block NSUInteger retries = 0;
        __block BOOL success = NO;
        CFDataRef replyData = NULL;
        SInt32 err = kCFMessagePortSuccess;
        SInt32 msgid = (SInt32)cmd; // 显式转换，避免精度丢失警告
        YKCFMessagePortErrorCode errorCode = YKCFMessagePortErrorUnknown;
        
        while (retries <= retryCount && !success) {
            err = CFMessagePortSendRequest(self->_remotePort,
                                           msgid,
                                           (__bridge CFDataRef)data,
                                           self.sendTimeout,   //发送超时秒
                                           self.rcvTimeout,    //回复超时秒
                                           kCFRunLoopDefaultMode,
                                           &replyData);
            if (err == kCFMessagePortSuccess) {
                success = YES;
                errorCode = YKCFMessagePortErrorSuccess;
            } else {
                if (err == kCFMessagePortIsInvalid) {
                    // 端口失效，释放旧端口，重新创建
                    CFRelease(self->_remotePort);
                    self->_remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)self->_portName);
                    if (!self->_remotePort) {
                        errorCode = YKCFMessagePortErrorRemotePortUnavailable;
                        break;
                    }
                } else if (err == kCFMessagePortSendTimeout) {
                    errorCode = YKCFMessagePortErrorSendTimeout;
                } else if (err == kCFMessagePortReceiveTimeout) {
                    errorCode = YKCFMessagePortErrorReceiveTimeout;
                } else {
                    errorCode = YKCFMessagePortErrorUnknown;
                }
                retries++;
                [NSThread sleepForTimeInterval:0.1];
            }
        }
        
        NSDictionary *replyDict = nil;
        if (replyData) {
            NSData *replyNSData = (__bridge_transfer NSData *)replyData;
            replyDict = YKCFMessagePortDeserializeData(replyNSData);
            if (!replyDict) {
                errorCode = YKCFMessagePortErrorSerializeFailed;
            }
        }
        
        if (handler) {
            dispatch_async(callbackQueue ?: dispatch_get_main_queue(), ^{
                handler(replyDict, errorCode);
            });
        }
    });
}

#pragma mark - 同步发送消息
-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSInteger)cmd {
    return [self sendSyncMessage:@{} cmd:cmd maxRetries:0];
}


-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSDictionary *)message cmd:(NSInteger)cmd {
    return [self sendSyncMessage:message cmd:cmd maxRetries:0];
}


#pragma mark - 同步发送消息，阻塞等待回复，支持指定最大重试次数
-(YKCFMessagePortSyncResult *)sendSyncMessage:(NSDictionary *)message
                                          cmd:(NSInteger)cmd
                                   maxRetries:(NSUInteger)retryCount
{
    // 确保远程端口有效，失败则重建
    if (!_remotePort) {
        _remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)_portName);
        if (!_remotePort) {
            return [YKCFMessagePortSyncResult resultWithError:YKCFMessagePortErrorRemotePortUnavailable reply:nil];
        }
    }
    
    NSData *data = YKCFMessagePortSerializeDictionary(message);
    if (!data) {
        return [YKCFMessagePortSyncResult resultWithError:YKCFMessagePortErrorSerializeFailed reply:nil];
    }
    
    __block YKCFMessagePortSyncResult *result = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block SInt32 err = kCFMessagePortSuccess;
    SInt32 msgid = (SInt32)cmd;
    
    dispatch_async(_queue, ^{
        NSUInteger retries = 0;
        BOOL success = NO;
        CFDataRef replyData = NULL;
        
        while (retries <= retryCount && !success)
        {
            err = CFMessagePortSendRequest(self->_remotePort,
                                           msgid,
                                           (__bridge CFDataRef)data,
                                           self.sendTimeout,
                                           self.rcvTimeout,
                                           kCFRunLoopDefaultMode,
                                           &replyData);
            
            if (err == kCFMessagePortSuccess) {
                success = YES;
            } else if (err == kCFMessagePortIsInvalid) {
                CFRelease(self->_remotePort);
                self->_remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)self->_portName);
                if (!self->_remotePort) {
                    err = YKCFMessagePortErrorRemotePortUnavailable;
                    break;
                }
            }
            
            if (!success) {
                retries++;
                [NSThread sleepForTimeInterval:0.1];
            }
        }
        
        if (success && replyData) {
            NSData *replyNSData = (__bridge_transfer NSData *)replyData;
            NSDictionary *replyDict = YKCFMessagePortDeserializeData(replyNSData);
            if (!replyDict) {
                result = [YKCFMessagePortSyncResult resultWithError:YKCFMessagePortErrorSerializeFailed reply:nil];
            } else {
                result = [YKCFMessagePortSyncResult resultWithError:YKCFMessagePortErrorSuccess reply:replyDict];
            }
        } else {
            result = [YKCFMessagePortSyncResult resultWithError:err reply:nil];
        }
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return result;
}

#pragma mark - 关闭远程端口，释放资源
-(void)invalidate
{
    if (_remotePort) {
        CFRelease(_remotePort);
        _remotePort = NULL;
    }
}

#pragma mark - 私有方法：创建远程端口
-(BOOL)_createRemotePortIfNeeded {
    if (_remotePort) return YES;
    if (!_portName) return NO;
    
    _remotePort = CFMessagePortCreateRemote(NULL, (__bridge CFStringRef)_portName);
    if (!_remotePort) {
        //LOGI(@"[YKCFMessagePortRemote] 创建远程 CFMessagePort 失败，端口名: %@", _portName);
        return NO;
    }
    return YES;
}

#pragma mark - 释放
-(void)dealloc
{
    [self invalidate];
}
@end


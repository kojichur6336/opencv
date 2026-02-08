//
//  YKCFMessagePortLocal.m
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import "YKXPCLogger.h"
#import "YKCFMessagePortLocal.h"

@interface YKCFMessagePortLocal () {
    CFMessagePortRef _localPort;              // 本地 CFMessagePort 实例（服务端）
    CFRunLoopSourceRef _runLoopSource;        // 运行循环源，用于监听消息
    CFRunLoopRef _runLoop;                    // 保存传入的 RunLoop 引用
    YKCFMessagePortSyncHandler _syncHandler;  // 同步消息回调
    NSString *_portName;                      // 端口名称
    dispatch_queue_t _handlerQueue;           // 用于保证 _syncHandler 串行执行
}
@end

@implementation YKCFMessagePortLocal


#pragma mark - CFMessagePort 消息回调函数，当收到消息时调用
static CFDataRef localCFMessagePortCallback(CFMessagePortRef local,
                                            SInt32 msgid,
                                            CFDataRef data,
                                            void *info)
{
    @try {
        
        YKCFMessagePortLocal *self = (__bridge YKCFMessagePortLocal *)info;
        if (!self->_syncHandler) {
            return NULL;
        }
        
        NSData *msgData = (__bridge NSData *)(data);
        
        // JSON -> NSDictionary
        NSDictionary *msgDict = nil;
        if (msgData) {
            msgDict = [NSJSONSerialization JSONObjectWithData:msgData options:0 error:nil];
            if (![msgDict isKindOfClass:[NSDictionary class]]) {
                msgDict = @{};
            }
        } else {
            msgDict = @{};
        }
        
        __block NSDictionary *replyDict = nil;
        if (self->_syncHandler) { // 再次判断，防止在回调中被释放
            replyDict = self->_syncHandler(msgid, msgDict);
        }
        
        // NSDictionary -> JSON
        NSData *replyData = nil;
        if (replyDict) {
            replyData = [NSJSONSerialization dataWithJSONObject:replyDict options:0 error:nil];
            return (__bridge_retained CFDataRef)replyData;
        }
        return NULL;
    } @catch (NSException *exception) {
        LOGI(@" ❌ messagePortCallBack exception: %@\n%@", exception.name, exception.reason);
    }
    return NULL;
}

#pragma mark - 初始化本地端口（服务端），指定端口名和同步消息处理回调
-(instancetype)initWithName:(NSString *)name runLoop:(CFRunLoopRef)runLoop syncHandler:(YKCFMessagePortSyncHandler)syncHandler
{
    self = [super init];
    if (self) {
        _portName = [name copy];
        _syncHandler = [syncHandler copy];
        _runLoop = runLoop;
        
        // 创建串行队列，保证 _syncHandler 的线程安全
        _handlerQueue = dispatch_queue_create("com.cyjh.mq.MQCFMessagePortLocal", DISPATCH_QUEUE_SERIAL);
        
        // 创建 CFMessagePortContext，持有 self 指针传递给回调
        CFMessagePortContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        Boolean shouldFreeInfo = false;
        
        // 创建本地端口，绑定回调函数
        _localPort = CFMessagePortCreateLocal(kCFAllocatorDefault, (__bridge CFStringRef)name, localCFMessagePortCallback, &context, &shouldFreeInfo);
        if (!_localPort) {
            LOGI(@"创建本地 CFMessagePort 失败，端口名: %@", name);
            return nil;
        }
        
        // 创建 RunLoopSource 并加入主线程 RunLoop，开始监听消息
        _runLoopSource = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localPort, 0);
        CFRunLoopAddSource(runLoop, _runLoopSource, kCFRunLoopCommonModes);
    }
    return self;
}

#pragma mark - 关闭本地端口，释放相关资源
-(void)invalidate
{
    // 用队列同步，确保在回调执行时不会释放资源
    dispatch_sync(_handlerQueue, ^{
        if (_runLoopSource) {
            CFRunLoopRemoveSource(_runLoop, _runLoopSource, kCFRunLoopCommonModes);
            CFRelease(_runLoopSource);
            _runLoopSource = NULL;
        }
        if (_localPort) {
            CFRelease(_localPort);
            _localPort = NULL;
        }
        _syncHandler = nil;
    });
}

#pragma mark - 释放内存
-(void)dealloc
{
    [self invalidate];
}
@end

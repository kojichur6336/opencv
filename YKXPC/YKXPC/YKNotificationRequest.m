//
//  YKNotificationRequest.m
//  YKXPC
//
//  Created by liuxiaobin on 2025/9/17.
//

#import "YKNotificationRequest.h"
#include <CoreFoundation/CoreFoundation.h>

CF_EXTERN_C_BEGIN
CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
CF_EXTERN_C_END

@interface YKNotificationRequest()
@property(nonatomic, readonly) dispatch_queue_t queue;
@property(nonatomic, strong) NSMutableDictionary<NSString *, YKNotificationCompletionHandler> *portCallbackMap;//保存每个Callback
@end

@implementation YKNotificationRequest

+(instancetype)shared {
    static YKNotificationRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[YKNotificationRequest alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.sky.yk.NotificationRequest", DISPATCH_QUEUE_SERIAL);
        _portCallbackMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - 添加监听通知
-(void)addNotificationWithObserver:(id)observer port:(NSString *)port completion:(YKNotificationCompletionHandler)completion {
    
    if (port.length == 0 || !completion)
    {
        return;
    }
    
    dispatch_async(self.queue, ^{
        // 判断是否已有对应端口的回调，避免重复添加通知
        if (self.portCallbackMap[port] != nil) {
            return;
        }
        
        // 注册 CFNotification
        CFStringRef portName = (__bridge CFStringRef)port;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                        (__bridge const void *)(self),
                                        MQNotificationCallback,
                                        portName,
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        
        // 保存回调
        self.portCallbackMap[port] = [completion copy];
    });
}

#pragma mark - 发送通知
-(void)postWithPort:(NSString *)port cmd:(NSInteger)cmd {
    
    @autoreleasepool {
        [self postWithPort:port cmd:cmd replyID:@"" data:@{}];
    }
}


#pragma mark - 发送通知
-(void)postWithPort:(NSString *)port data:(NSDictionary *)data {
    
    @autoreleasepool {
        [self postWithPort:port cmd:0 replyID:@"" data:data];
    }
}


#pragma mark - 发送通知
-(void)postWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data {
    
    @autoreleasepool {
        [self postWithPort:port cmd:cmd replyID:@"" data:data];
    }
}


#pragma mark - 发送通知
-(void)postWithPort:(NSString *)port cmd:(NSInteger)cmd replyID:(NSString *)replyID data:(NSDictionary *)data {
    
    @autoreleasepool {
        
        CFStringRef portName = (__bridge CFStringRef)port;
        NSDictionary *userInfo = @{@"cmd": @(cmd), @"data": data, @"replyID": replyID};
        CFNotificationCenterPostNotificationWithOptions(CFNotificationCenterGetDistributedCenter(), portName, NULL, (__bridge CFDictionaryRef)userInfo, 0);
    }
}


#pragma mark - 发送请求带超时（局部信号量 + 动态监听 + 自动清理）
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd {
    
    return [self sendRequestWithPort:port cmd:cmd data:@{} timeout:60 * 60];
}

#pragma mark - 发送请求带超时（局部信号量 + 动态监听 + 自动清理）
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data {
    
    return [self sendRequestWithPort:port cmd:cmd data:data timeout:60 * 60];
}

#pragma mark - 发送请求带超时（局部信号量 + 动态监听 + 自动清理）
-(NSDictionary *)sendRequestWithPort:(NSString *)port cmd:(NSInteger)cmd data:(NSDictionary *)data timeout:(NSTimeInterval)timeout
{
    if (port.length == 0) return nil;
    
    // 生成唯一 replyID 作为监听端口，确保每次监听独立
    NSString *replyID = [[NSUUID UUID] UUIDString];
    
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSDictionary * responseResult = nil;
    
    // 动态添加监听，监听唯一的 requestId 端口
    __weak typeof(self) weakSelf = self;
    [self addNotificationWithObserver:self port:replyID completion:^(NSInteger cmd, NSString * _Nonnull replyID, NSDictionary * _Nonnull messageData) {
       
        responseResult = messageData;
        // 收到回执后移除监听，释放信号量
        [weakSelf removeNotificationForPort:replyID];
        dispatch_semaphore_signal(sema);
    }];
    
    
    [self postWithPort:port cmd:cmd replyID:replyID data:data];
    
    // 等待回执或者超时
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    if (dispatch_semaphore_wait(sema, waitTime) != 0) {
        // 超时移除监听，避免泄露
        [self removeNotificationForPort:replyID];
        return nil;
    }
    
    return responseResult;
}


#pragma mark - 通知回调
void MQNotificationCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    
    YKNotificationRequest *request = (__bridge YKNotificationRequest *)observer;
    NSDictionary *userInfoDict = (__bridge NSDictionary *)userInfo;
    NSString *port = (__bridge NSString *)name;
    
    NSInteger cmd = [userInfoDict[@"cmd"] intValue];
    NSDictionary *data = userInfoDict[@"data"];
    NSString *replyID = userInfoDict[@"replyID"];
    
    dispatch_async(request.queue, ^{
        YKNotificationCompletionHandler callback = request.portCallbackMap[port];
        if (callback) {
            callback(cmd, replyID, data);
        }
    });
}


#pragma mark - 移除端口监听
-(void)removeNotificationForPort:(NSString *)port
{
    if (port.length == 0) return;
    dispatch_async(self.queue, ^{
        CFStringRef portName = (__bridge CFStringRef)port;
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDistributedCenter(),
                                           (__bridge const void *)(self),
                                           portName,
                                           NULL);
        [self.portCallbackMap removeObjectForKey:port];
    });
}
@end

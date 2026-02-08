//
//  YKPortScanManager.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKServiceTool.h"
#import "YKPortScanWIFI.h"
#import "YKServiceLogger.h"
#import "YKServiceEncrypt.h"
#import "YKPortScanManager.h"

@interface YKPortScanManager()
@property(nonatomic, strong) YKPortScanWIFI *wifiPort;//WIFI端口
@property(nonatomic, assign) uint16_t port;
@property(nonatomic, weak) id<YKPortScanManagerDelegate> delegate;
@end

@interface YKPortScanManager(PortScanWIFIDelegate) <YKPortScanWIFIDelegate>
@end


@implementation YKPortScanManager

-(instancetype)initWithPort:(uint16_t)port delegate:(id<YKPortScanManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _port = port;
        _delegate = delegate;
    }
    return self;
}


#pragma mark - 开始
-(BOOL)startWithError:(NSError *__autoreleasing  _Nullable *)error
{
    
    if (![self.wifiPort startWithError:error]) {
        return NO;
    }
    return YES;
}


#pragma mark - 停止
-(void)stop
{
    [self.wifiPort stop];
}


#pragma mark - lazy
-(YKPortScanWIFI *)wifiPort
{
    if (!_wifiPort) {
        _wifiPort = [[YKPortScanWIFI alloc] initWithPort:_port delegate:self];
    }
    return _wifiPort;
}
@end



//============================================================
// WIFI端口UDP回调
//============================================================
@implementation YKPortScanManager(PortScanWIFIDelegate)
-(void)ykpswifi_didReceiveUDPMessageWithLogin:(NSString *)ip ykpswifi_data:(NSData *)data
{
    NSData *jsonData = [YKServiceEncrypt yk_aesDecrypt:data];
    NSDictionary *json = [YKServiceTool jsonData:jsonData];
    if (!json) {
        LOGI(@"UDP数据解析失败");
        return;
    }
    NSString *remoteDeviceName = json[@"remoteDeviceName"];
    if (remoteDeviceName.length <= 0) {
        remoteDeviceName = @"设备";//默认名称
    }
    [_delegate ykpsm_portScanManager:self ykpsm_ip:json[@"ip"] ykpsm_port:[json[@"port"] intValue] ykpsm_remoteDeviceName:remoteDeviceName];
}
@end

//
//  YKAirPlayServiceRegister.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/22.
//

#import <dns_sd.h>
#import "YKServiceLogger.h"
#import "YKAirPlayServiceRegister.h"

@interface YKAirPlayServiceRegister()
@property(nonatomic, assign) int port;//端口
@property(nonatomic, copy) NSString *deviceId;//设备ID
@property(nonatomic, copy) NSString *airPlayName;//镜像发现的名称
@property(nonatomic, assign) DNSServiceRef airPlaytcpServiceRef;  // DNSServiceRef 属性
@property(nonatomic, assign) DNSServiceRef raoptcpServiceRef; // DNSServiceRef 属性
@end

@implementation YKAirPlayServiceRegister

-(instancetype)initWithPort:(int)port
{
    self = [super init];
    if (self) {
        
        _port = port;
        _deviceId = [[NSUUID new] UUIDString];
    }
    return self;
}


#pragma mark - 服务注册
-(BOOL)serviceRegister:(NSString *)airPalyName
{
    _airPlayName = airPalyName;
    if ([self crateAirPlayTCP] && [self createRaoPTCP])
    {
        return true;
    } else {
        return false;
    }
}

#pragma mark - 创建_airplay._tcp
-(BOOL)crateAirPlayTCP {
    
    //LOGI(@"创建_airplay._tcp");
    NSString *features = @"0x5A7FFFF7,0x1E";//不能改,Hook到的唯一值
    NSString *model = @"AppleTV3,2";
    NSString *srcvers = @"220.68";
    NSString *vv = @"2";
    NSString *pi = @"b08f5a79-1b29-4384-b456-a4784d9e6055";
    NSString *flags = @"0x44";
    NSString *pk = @"13d18e46fcd95587a70c9bd6e4a64a593c789cdd14c0ec8318d2651b43290eaa";
    NSString *ch = @"2";
    NSString *cn = @"0,1,2,3";
    NSString *sf = @"0x44";
    
    
    TXTRecordRef trrAirplay;
    
    // 创建TXT记录
    TXTRecordCreate(&trrAirplay, 0, NULL);
    
    // 设置 TXT 记录的值
    TXTRecordSetValue(&trrAirplay, "deviceId", (uint8_t)_deviceId.length, _deviceId.UTF8String);
    TXTRecordSetValue(&trrAirplay, "features", (uint8_t)features.length, features.UTF8String);
    TXTRecordSetValue(&trrAirplay, "model", (uint8_t)model.length, model.UTF8String);
    TXTRecordSetValue(&trrAirplay, "srcvers", (uint8_t)srcvers.length, srcvers.UTF8String);
    TXTRecordSetValue(&trrAirplay, "vv", (uint8_t)vv.length, vv.UTF8String);
    TXTRecordSetValue(&trrAirplay, "pi", (uint8_t)pi.length, pi.UTF8String);
    TXTRecordSetValue(&trrAirplay, "flags", (uint8_t)flags.length, flags.UTF8String);
    TXTRecordSetValue(&trrAirplay, "pk", (uint8_t)pk.length, pk.UTF8String);
    TXTRecordSetValue(&trrAirplay, "ch", (uint8_t)ch.length, ch.UTF8String);
    TXTRecordSetValue(&trrAirplay, "cn", (uint8_t)cn.length, cn.UTF8String);
    TXTRecordSetValue(&trrAirplay, "sf", (uint8_t)sf.length, sf.UTF8String);
    
    
    //0xFFFFFFFFLL 这个值很关键,能让自己的设备发现自己,别人的发现不了
    DNSServiceErrorType result = DNSServiceRegister(&_airPlaytcpServiceRef, 0, 0xFFFFFFFFLL, _airPlayName.UTF8String, "_airplay._tcp.", "local", NULL, htons(_port + 1), TXTRecordGetLength(&trrAirplay), TXTRecordGetBytesPtr(&trrAirplay), NULL, NULL);
    return result == 0 ? YES : NO;
}

#pragma mark - 创建_raop._tcp
-(BOOL)createRaoPTCP {
    
    //LOGI(@"创建_raop._tcp");
    
    NSString *txtvers = @"1";
    NSString *ch = @"2";
    NSString *cn = @"0,1,2,3";
    NSString *da = @"true";
    NSString *et = @"0,3,5";
    NSString *ft = @"0x5A7FFFF7,0x1E";
    NSString *md = @"0,1,2";
    NSString *pw = @"false";
    NSString *sv = @"false";
    NSString *sr = @"44100";
    NSString *ss = @"16";
    NSString *tp = @"UDP";
    NSString *vs = @"220.68";
    NSString *vv = @"2";
    NSString *vn = @"65537";
    NSString *am = @"AppleTV3,2";
    NSString *sf = @"0x44";
    NSString *pk = @"13d18e46fcd95587a70c9bd6e4a64a593c789cdd14c0ec8318d2651b43290eaa";
    
    TXTRecordRef trrRaop;
    TXTRecordCreate(&trrRaop, 0, NULL);
    
    // 设置 Raop 记录的值
    TXTRecordSetValue(&trrRaop, "txtvers", (uint8_t)txtvers.length, txtvers.UTF8String);
    TXTRecordSetValue(&trrRaop, "ch", (uint8_t)ch.length, ch.UTF8String);
    TXTRecordSetValue(&trrRaop, "cn", (uint8_t)cn.length, cn.UTF8String);
    TXTRecordSetValue(&trrRaop, "da", (uint8_t)da.length, da.UTF8String);
    TXTRecordSetValue(&trrRaop, "et", (uint8_t)et.length, et.UTF8String);
    TXTRecordSetValue(&trrRaop, "ft", (uint8_t)ft.length, ft.UTF8String);
    TXTRecordSetValue(&trrRaop, "md", (uint8_t)md.length, md.UTF8String);
    TXTRecordSetValue(&trrRaop, "pw", (uint8_t)pw.length, pw.UTF8String);
    TXTRecordSetValue(&trrRaop, "sv", (uint8_t)sv.length, sv.UTF8String);
    TXTRecordSetValue(&trrRaop, "sr", (uint8_t)sr.length, sr.UTF8String);
    TXTRecordSetValue(&trrRaop, "ss", (uint8_t)ss.length, ss.UTF8String);
    TXTRecordSetValue(&trrRaop, "tp", (uint8_t)tp.length, tp.UTF8String);
    TXTRecordSetValue(&trrRaop, "vs", (uint8_t)vs.length, vs.UTF8String);
    TXTRecordSetValue(&trrRaop, "vv", (uint8_t)vv.length, vv.UTF8String);
    TXTRecordSetValue(&trrRaop, "vn", (uint8_t)vn.length, vn.UTF8String);
    TXTRecordSetValue(&trrRaop, "am", (uint8_t)am.length, am.UTF8String);
    TXTRecordSetValue(&trrRaop, "sf", (uint8_t)sf.length, sf.UTF8String);
    TXTRecordSetValue(&trrRaop, "pk", (uint8_t)am.length, pk.UTF8String);
    
    
    NSString *name = [NSString stringWithFormat:@"%@%@%@",_deviceId, @"@",_airPlayName];//这边一定要组合起来并且一定要加@
    DNSServiceErrorType result = DNSServiceRegister(&_raoptcpServiceRef, 0, 0xFFFFFFFFLL, name.UTF8String, "_raop._tcp.", "local", NULL, htons(_port), TXTRecordGetLength(&trrRaop), TXTRecordGetBytesPtr(&trrRaop), NULL, NULL);
    return result == 0 ? YES : NO;
}

#pragma mark - 取消注册
-(void)deallocate {
    
    if (_airPlaytcpServiceRef) {
        DNSServiceRefDeallocate(_airPlaytcpServiceRef);
    }
    
    if (_raoptcpServiceRef) {
        DNSServiceRefDeallocate(_raoptcpServiceRef);
    }
}
@end

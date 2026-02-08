//
//  YKServiceModel.m
//  YKService
//
//  Created by liuxiaobin on 2025/12/27.
//

#import "YKServiceModel.h"

@implementation YKServiceModel


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.isServiceEnabled forKey:@"isServiceEnabled"];
    [coder encodeInt:self.autoReconnectInterval forKey:@"autoReconnectInterval"];
    
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _isServiceEnabled = [coder decodeBoolForKey:@"isServiceEnabled"];
        _autoReconnectInterval = [coder decodeIntForKey:@"autoReconnectInterval"];
    }
    return self;
}

#pragma mark - 本地持久化逻辑
+(NSString *)configFilePath {
    return @"/var/mobile/Library/YKApp/Config/com.service.config.data";
}

+(instancetype)loadFromDisk {
    
    NSData *data = [NSData dataWithContentsOfFile:[self configFilePath]];
    if (data) {
        return [NSKeyedUnarchiver unarchivedObjectOfClass:self fromData:data error:nil];
    }
    
    // 默认
    YKServiceModel *model = [[YKServiceModel alloc] init];
    model.isServiceEnabled = YES;
    model.autoReconnectInterval = 60;
    [model saveToDisk];
    return model;
}

-(void)saveToDisk
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:nil];
    if (data) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[self.class configFilePath] stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        [data writeToFile:[self.class configFilePath] atomically:YES];
    }
}
@end

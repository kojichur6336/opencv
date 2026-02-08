//
//  YKApplicationManager.m
//  Created on 2025/10/15
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <dlfcn.h>
#import <sqlite3.h>
#import <mach-o/fat.h>
#import <mach-o/arch.h>
#import <UIKit/UIKit.h>
#import "YKConstants.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/loader.h>
#import "YKServiceTool.h"
#import "YKServiceShell.h"
#import "YKServiceLogger.h"
#import "YKApplicationManager.h"
#import <YKZipKit/YKZipManager.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@interface LSApplicationWorkspace : NSObject
+(id)defaultWorkspace;
- (BOOL)installApplication:(NSURL*)bundleURL
               withOptions:(NSDictionary*)options
                     error:(NSError**)error
                usingBlock:(void(^)(id progress))block;
-(BOOL)uninstallApplication:(NSString*)appId withOptions:(NSDictionary*)options;
@end

@implementation YKApplicationManager

#pragma mark - 安装App
+(void)installApp:(NSString *)path completion:(InstallCompletionBlock)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self checkIPAAtPath:path completion:^(NSString * _Nonnull bundleID, BOOL encrypted, NSString * _Nonnull version, NSString * _Nonnull build, NSString * _Nonnull error)
         {
            if (error.length <= 0) {
                
                if (encrypted) {
                    LOGI(@"未破解,加密包");
                    [self installIPAWithBid:bundleID path:path version:version build:build completion:completion];
                } else {
                    
                    NSString* helperPath = [self getTrollStoreHelper];
                    if (helperPath == nil) {
                        LOGI(@"没有安装巨魔,还是走系统的安装流程");
                        [self installIPAWithBid:bundleID path:path version:version build:build completion:completion];
                    } else {
                        LOGI(@"砸壳包,解密包");
                        [self installDecryptIPAWithBundleId:bundleID path:path version:version build:build completion:completion];
                    }
                }
            } else {
                completion(NO, error);
            }
        }];
    });
}


#pragma mark - 安装IPA包
+(void)installIPAWithBid:(NSString *)bundleId path:(NSString *)path version:(NSString *)version build:(NSString *)build completion:(InstallCompletionBlock)completion
{
    
    id workspace = [LSApplicationWorkspace defaultWorkspace];
    if (!workspace) {
        if (completion) {
            completion(NO, @"找不到 LSApplicationWorkspace");
        }
        return;
    }
    
    NSDictionary *oldAppInfo = [self getInstalledAppVersion:bundleId];
    LOGI(@"安装前版本: %@", oldAppInfo ?: @"未安装");
    if (oldAppInfo) {
        
        NSString *oldVersion = oldAppInfo[@"shortVersion"];
        NSString *oldBuild = oldAppInfo[@"buildVersion"];
        if ([oldVersion isEqualToString:version] && [build isEqualToString:oldBuild]) {
            completion(YES, @"两个版本号跟构建版本都一样不需要重复安装,默认直接给安装成功!");
            return;
        }
    }
    
    NSDictionary *options = @{@"CFBundleIdentifier": bundleId};
    __block BOOL hasReturned = NO;
    
    
    // ---- 无限轮询逻辑：每 5 秒检查一次, 因为在安装包很大的情况下，安装结果不会有返回值。 ----
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), 5 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        
        if (hasReturned) {
            dispatch_source_cancel(timer);
            return;
        }
        
        NSDictionary *newAppInfo = [self getInstalledAppVersion:bundleId];
        if (newAppInfo) {
            
            NSString *newVersion = newAppInfo[@"shortVersion"];
            NSString *newBuild = newAppInfo[@"buildVersion"];
            if ([newVersion isEqualToString:version] && [build isEqualToString:newBuild]) {
                hasReturned = YES;
            }
        }
        
        if (hasReturned) {
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(YES, @"安装成功（版本变化确认）");
            });
        }
    });
    dispatch_resume(timer);
    
    
    BOOL result = [workspace installApplication:[NSURL fileURLWithPath:path]
                                    withOptions:options
                                          error:nil
                                     usingBlock:^(id progress) {
        // 进度必须是 NSDictionary 类型
        if ([progress isKindOfClass:[NSDictionary class]]) {
            //NSDictionary *info = (NSDictionary *)progress;
            //int percent = [info[@"PercentComplete"] intValue];
            //NSString *status = info[@"Status"];
            //LOGI(@"输出结果%@",status);
        }
    }];
    if (!result)
    {
        dispatch_source_cancel(timer);
        completion(NO, @"安装失败");
    }
}

#pragma mark - 安装解密包
+(void)installDecryptIPAWithBundleId:(NSString *)bundleId path:(NSString *)path version:(NSString *)version build:(NSString *)build completion:(void (^)(BOOL, NSString * _Nonnull))completion
{
    
    NSDictionary *oldAppInfo = [self getInstalledAppVersion:bundleId];
    LOGI(@"安装前版本: %@", oldAppInfo ?: @"未安装");
    if (oldAppInfo) {
        
        NSString *oldVersion = oldAppInfo[@"shortVersion"];
        NSString *oldBuild = oldAppInfo[@"buildVersion"];
        if ([oldVersion isEqualToString:version] && [build isEqualToString:oldBuild]) {
            completion(YES, @"两个版本号跟构建版本都一样不需要重复安装,默认直接给安装成功!");
            return;
        }
    }
    
    
    __block BOOL hasReturned = NO;
    
    // ---- 无限轮询逻辑：每 5 秒检查一次, 因为在安装包很大的情况下，安装结果不会有返回值。 ----
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), 5 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        
        if (hasReturned) {
            dispatch_source_cancel(timer);
            return;
        }
        
        NSDictionary *newAppInfo = [self getInstalledAppVersion:bundleId];
        if (newAppInfo) {
            
            NSString *newVersion = newAppInfo[@"shortVersion"];
            NSString *newBuild = newAppInfo[@"buildVersion"];
            if ([newVersion isEqualToString:version] && [build isEqualToString:newBuild]) {
                hasReturned = YES;
            }
        }
        
        if (hasReturned) {
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(YES, @"安装成功（版本变化确认）");
            });
        }
    });
    dispatch_resume(timer);
    
    
    // 调用安装命令，不管返回值，轮询一直运行直到成功回调
    NSString* helperPath = [self getTrollStoreHelper];
    NSArray* cmdArgv = @[helperPath, @"install", @"force", path];
    [YKServiceShell spawnWithArgs:cmdArgv stdOut:nil flag:0];
}



#pragma mark - 提出Ipa信息
+(void)checkIPAAtPath:(NSString *)ipaPath
           completion:(void (^)(NSString *bundleID, BOOL encrypted, NSString *version, NSString *build, NSString *error))completion
{
    
    NSString *bundleID = @"";
    BOOL encrypted = NO;
    NSString *version = @"";
    NSString *build = @"";
    
    // 解压 IPA 到临时目录
    NSString *tempDir = [NSString stringWithFormat:@"%@%@",YK_DOWNLOADS_PATH,[[NSUUID UUID] UUIDString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager createDirectoryAtPath:tempDir
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:nil];
    
    
    YKZipManager * zipManager = new YKZipManager();
    zipManager->open(ipaPath.UTF8String, nullptr);
    NSString *appName = zipManager->getIPAName();
    BOOL result1 = zipManager->extractFileAtPathFromIPA([NSString stringWithFormat:@"Payload/%@.app/%@",appName,appName],tempDir);
    BOOL result2 = zipManager->extractFileAtPathFromIPA([NSString stringWithFormat:@"Payload/%@.app/%@",appName,@"info.plist"],tempDir);
    zipManager->close();
    delete zipManager;
    zipManager = nil;
    LOGI(@"输出结果是result1=%d,result2=%d",result1, result2);
    if (result1 || result2) {
        
        // 遍历临时目录，查找带有 .plist 后缀的文件以及不带 .plist 后缀的文件
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *fileContents = [fileManager contentsOfDirectoryAtPath:tempDir error:nil];
        
        NSString *plistFilePath = @"";
        NSString *executableFilePath = @"";
        
        for (NSString *fileName in fileContents) {
            NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
            
            // 检查文件是否为 .plist 文件
            if ([fileName hasSuffix:@".plist"]) {
                plistFilePath = filePath; // 记录 .plist 文件的路径
            } else {
                executableFilePath = filePath; // 记录非 .plist 文件的路径
            }
        }
        
        // 执行业务逻辑：根据找到的文件执行相应的操作
        if (plistFilePath.length > 0) {
            
            // 处理 plist 文件，解析获取 bundleID、version、build 等信息
            NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
            if (plistDict) {
                bundleID = plistDict[@"CFBundleIdentifier"] ?: @"";
                version = plistDict[@"CFBundleShortVersionString"] ?: @"";
                build = plistDict[@"CFBundleVersion"] ?: @"";
            }
        }
        
        if (executableFilePath.length > 0) {
            
            // 处理没有 .plist 后缀的文件（比如可执行文件）
            // 你可以在这里添加额外的逻辑来判断文件是否加密等
            encrypted = [self isExecutableEncrypted:executableFilePath]; // 判断可执行文件是否加密
        }
        
        // 删除临时目录
        [[NSFileManager defaultManager] removeItemAtPath:tempDir error:nil];
        // 调用 completion 回调，返回结果
        completion(bundleID, encrypted, version, build, @"");
        
    } else {
        
        completion(bundleID, encrypted, @"", @"", @"解压失败");
        return;
    }
}



/// 判断一个可执行文件是否加密（用于已定位的 Mach-O 文件路径）
/// @param binaryPath 可执行文件路径
+(BOOL)isExecutableEncrypted:(NSString *)binaryPath {
    FILE *fp = fopen([binaryPath UTF8String], "rb");
    if (!fp) return NO;
    
    // 读取 magic 判断是否为 Mach-O
    uint32_t magic = 0;
    fread(&magic, sizeof(uint32_t), 1, fp);
    fseek(fp, 0, SEEK_SET); // 复位
    
    BOOL encrypted = NO;
    
    if (magic == MH_MAGIC_64) {
        // 读取 64 位 Mach-O header
        struct mach_header_64 mh;
        fread(&mh, sizeof(mh), 1, fp);
        
        for (uint32_t i = 0; i < mh.ncmds; i++) {
            long pos = ftell(fp);
            struct load_command lc;
            fread(&lc, sizeof(lc), 1, fp);
            fseek(fp, pos, SEEK_SET);
            
            if (lc.cmd == LC_ENCRYPTION_INFO_64) {
                struct encryption_info_command_64 enc;
                fread(&enc, sizeof(enc), 1, fp);
                encrypted = (enc.cryptid != 0);
                break;
            } else {
                fseek(fp, lc.cmdsize, SEEK_CUR);
            }
        }
    } else if (magic == FAT_CIGAM) {
        // FAT 二进制（可选：暂不解析 fat binary）
        LOGI(@"⚠️ fat binary 暂未处理");
    } else {
        LOGI(@"❌ 不是有效的 Mach-O 可执行文件");
    }
    
    fclose(fp);
    return encrypted;
}


#pragma mark - 获取巨魔的安装可执行文件
+(NSString *)getTrollStoreHelper {
    
    NSString* trollStoreBundlePath = nil;
    NSString* appContainersPath = @"/var/containers/Bundle/Application";
    NSError* error;
    NSArray* containers = [NSFileManager.defaultManager contentsOfDirectoryAtPath:appContainersPath error:&error];
    for(NSString* container in containers) {
        NSString* containerPath = [appContainersPath stringByAppendingPathComponent:container];
        NSString* trollStoreApp = [containerPath stringByAppendingPathComponent:@"TrollStore.app"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:trollStoreApp]) {
            trollStoreBundlePath = trollStoreApp;
            break;
        }
    }
    if (trollStoreBundlePath == nil) {
        return nil;
    }
    NSString* helperPath = [trollStoreBundlePath stringByAppendingPathComponent:@"trollstorehelper"];
    if (![NSFileManager.defaultManager fileExistsAtPath:helperPath]) {
        return nil;
    }
    return helperPath;
}

#pragma mark - 获取安装包版本信息
+(NSDictionary *)getInstalledAppVersion:(NSString *)bundleId {
    
    Class LSApplicationWorkspace = objc_getClass("LSApplicationWorkspace");
    NSObject *ws = [LSApplicationWorkspace performSelector:@selector(defaultWorkspace)];
    NSArray *apps = [ws performSelector:@selector(allApplications)];
    for (id app in apps) {
        NSString *appId = [app performSelector:@selector(applicationIdentifier)];
        if ([appId isEqualToString:bundleId]) {
            // 取版本号
            NSString *version = [app performSelector:@selector(bundleVersion)];
            NSString *shortVersionString = [app performSelector:@selector(shortVersionString)];
            
            return @{
                @"buildVersion": version ?: @"",
                @"shortVersion": shortVersionString ?: @""
            };
        }
    }
    return nil;
}


/// 遍历数组查看是否有标签
/// - Parameters:
///   - tagArr: 数组
///   - tag: tag description
BOOL tagArrayContainsTag(NSArray* tagArr, NSString* tag)
{
    if(!tagArr || !tag) return NO;
    
    __block BOOL found = NO;
    
    [tagArr enumerateObjectsUsingBlock:^(NSString* tagToCheck, NSUInteger idx, BOOL* stop)
     {
        if(![tagToCheck isKindOfClass:[NSString class]])
        {
            return;
        }
        
        if([tagToCheck rangeOfString:tag options:0].location != NSNotFound)
        {
            found = YES;
            *stop = YES;
        }
    }];
    
    return found;
}

+ (NSString *)getChineseNameFromBundleURL:(NSURL *)bundleURL {
    if (!bundleURL) return nil;
    
    // 尝试寻找简体中文本地化资源目录
    // 常见的后缀：zh_CN.lproj, zh-Hans.lproj, zh_Hans.lproj
    NSArray *lprojDirs = @[@"zh-Hans.lproj", @"zh_CN.lproj", @"zh_Hans.lproj", @"zh-Hant.lproj"];
    
    for (NSString *dirName in lprojDirs) {
        NSURL *stringsURL = [bundleURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/InfoPlist.strings", dirName]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:stringsURL.path]) {
            // InfoPlist.strings 是二进制或文本的 plist
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:stringsURL];
            if (dict) {
                // 优先取 DisplayName (桌面显示名)，没有则取 Name (包名)
                NSString *name = dict[@"CFBundleDisplayName"] ?: dict[@"CFBundleName"];
                if (name.length > 0) return name;
            }
        }
    }
    
    // 如果找不到多语言文件，尝试直接读取 Info.plist
    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfURL:[bundleURL URLByAppendingPathComponent:@"Info.plist"]];
    return infoDict[@"CFBundleDisplayName"] ?: infoDict[@"CFBundleName"];
}

#pragma mark - 获取应用列表
+(void)getAppsList:(AppsListCompletionBlock)completion
{
    // 1. 定义黑名单
    static NSSet *blacklistedIdentifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blacklistedIdentifiers = [NSSet setWithArray:@[
            @"com.sky.ykpro",
            @"com.opa334.Dopamine-roothide",
            @"com.opa334.Dopamine",
            @"org.coolstar.SileoStore",
            @"com.saurik.Cydia",
            @"com.apple.PosterBoard",
            @"com.apple.siri",
            @"com.apple.dt.XcodePreviews",
            @"com.apple.sidecar",
            @"com.apple.mobilesafari",
        ]];
    });
    
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableSet *seenIdentifiers = [NSMutableSet set];
    
    Class LSApplicationWorkspace = objc_getClass("LSApplicationWorkspace");
    id workspace = [LSApplicationWorkspace performSelector:@selector(defaultWorkspace)];
    NSArray *allApps = [workspace performSelector:@selector(allApplications)];
    
    for (id app in allApps) {
        // app 实际上是 LSApplicationProxy 对象
        NSString *identifier = [app performSelector:@selector(applicationIdentifier)];
        
        // --- 过滤逻辑 ---
        if (!identifier || [seenIdentifiers containsObject:identifier]) continue;
        if ([identifier hasSuffix:@".appex"]) continue;
        if ([blacklistedIdentifiers containsObject:identifier]) continue;
        if ([self getHiddenWithLSApplicationProxy:app]) continue;
        
        [seenIdentifiers addObject:identifier];
        
        // --- 获取版本号 (优先从 Proxy 获取，减少 IO) ---
        NSString *version = @"";
        if ([app respondsToSelector:@selector(shortVersionString)]) {
            version = [app performSelector:@selector(shortVersionString)];
        }
        
        // --- 获取应用名称 ---
        // localizedName 通常已经处理了多语言。
        // 如果你发现拿不到中文，是因为系统语言没切到中文。
        // 如果非要从 Info.plist 拿，建议如下：
        
        // --- 获取 App 名称的核心逻辑 ---
        NSURL *bundleURL = [app performSelector:@selector(bundleURL)];
        
        // 1. 优先尝试从本地化文件直接读取（最准，强制中文）
        NSString *appName = [self getChineseNameFromBundleURL:bundleURL];
        
        // 2. 如果手动读取失败，再用系统提供的 localizedName
        if (appName.length == 0) {
            appName = [app performSelector:@selector(localizedName)];
        }
        
        // 3. 最后兜底
        if (appName.length == 0) appName = @"未知应用";
        
        // --- 组装数据 ---
        NSMutableDictionary *appInfo = [[NSMutableDictionary alloc] init];
        appInfo[@"identifier"] = identifier;
        appInfo[@"name"] = appName;
        appInfo[@"version"] = version ?: @"1.0.0";
        
        // 类型处理
        NSString *appType = [app performSelector:@selector(applicationType)];
        int typeNum = 0;
        if ([appType isEqualToString:@"User"]) {
            typeNum = 1;
        } else if ([appType isEqualToString:@"System"]) {
            typeNum = 2;
        }
        appInfo[@"type"] = @(typeNum);
        
        
        if ([app respondsToSelector:@selector(isDeletable)]) {
            
            BOOL isDeletable = [app performSelector:@selector(isDeletable)];
            if (isDeletable == NO && ([identifier hasPrefix:@"com.apple"] || [identifier hasPrefix:@"com.roothide"] || [identifier hasPrefix:@"org.coolstar"])) {
                isDeletable = NO;
            } else {
                isDeletable = YES;
            }
            appInfo[@"isDeletable"] = @(isDeletable);
        }
        
        // --- 图标处理 ---
        // 建议：如果列表很大，不要在这里转 Base64，会导致内存瞬间飙升。
        // 这里只存 identifier，UI 渲染时再根据 identifier 动态取图标。
        UIImage *icon = [YKServiceTool getAppIconForIdentifier:identifier];
        if (icon) {
            NSData *imageData = UIImagePNGRepresentation(icon);
            // 只有小图标适合转 Base64，如果是为了传给前端/H5，请务必压缩
            appInfo[@"icon"] = [imageData base64EncodedStringWithOptions:0] ?: @"";
        } else {
            appInfo[@"icon"] = @"";
        }
        
        [array addObject:appInfo];
    }
    
    if (completion) {
        completion(array);
    }
}


/// 判断是否隐藏
/// - Parameter app: app
+(BOOL)getHiddenWithLSApplicationProxy:(id)app {
    
    NSString *bundleIdentifier = @"";
    if ([app respondsToSelector:@selector(applicationIdentifier)]) {
        bundleIdentifier = [app performSelector:@selector(applicationIdentifier)];
    }
    
    // 是否隐藏应用判断
    NSArray *appTags = nil;
    NSArray *recordAppTags = nil;
    NSArray *sbAppTags = nil;
    BOOL launchProhibited = NO;
    
    // 获取对应的 application record
    if ([app respondsToSelector:@selector(correspondingApplicationRecord)]) {
        id record = [app performSelector:@selector(correspondingApplicationRecord)];
        
        // 获取 appTags 和 launchProhibited
        if ([record respondsToSelector:@selector(appTags)]) {
            recordAppTags = [record performSelector:@selector(appTags)];
        }
        if ([record respondsToSelector:@selector(launchProhibited)]) {
            launchProhibited = [[record performSelector:@selector(launchProhibited)] boolValue];
        }
    }
    
    // 获取 appTags
    if ([app respondsToSelector:@selector(appTags)]) {
        appTags = [app performSelector:@selector(appTags)];
    }
    
    // 获取 launchProhibited
    if (!launchProhibited && [app respondsToSelector:@selector(isLaunchProhibited)]) {
        launchProhibited = [app performSelector:@selector(isLaunchProhibited)];
    }
    
    // 获取 bundleURL
    NSURL *bundleURL = nil;
    if ([app respondsToSelector:@selector(bundleURL)]) {
        bundleURL = [app performSelector:@selector(bundleURL)];
    }
    
    if (bundleURL && [bundleURL checkResourceIsReachableAndReturnError:nil]) {
        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        sbAppTags = [bundle objectForInfoDictionaryKey:@"SBAppTags"];
    }
    
    // 判断是否为 Web 应用
    BOOL isWebApplication = ([bundleIdentifier rangeOfString:@"com.apple.webapp" options:NSCaseInsensitiveSearch].location != NSNotFound);
    
    // 判断是否隐藏
    return tagArrayContainsTag(appTags, @"hidden") ||
    tagArrayContainsTag(recordAppTags, @"hidden") ||
    tagArrayContainsTag(sbAppTags, @"hidden") ||
    isWebApplication ||
    launchProhibited;
}

#pragma mark - 卸载App
+(BOOL)uninstallApp:(NSString *)bundleId {
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    // 判断是否有按照这个app
    BOOL isInstall = [workspace performSelector:@selector(applicationIsInstalled:) withObject:bundleId];
    if (isInstall)
    {
        @try {
            BOOL (*uninstallapp)(id, SEL, id, id) = (BOOL(*)(id,SEL,id,id))objc_msgSend;
            BOOL result = uninstallapp(workspace, @selector(uninstallApplication:withOptions:),bundleId, nil);
            return result;
        } @catch (NSException *e) {
            return NO;
        }
    } else {
        return NO;
    }
    
    
}


#pragma mark - 查询这个包是否是Deb包
+(BOOL)isDebPackage:(NSString *)bundleId {
    
    NSString *path = [YKServiceTool conversionJBRoot:@"/var/lib/dpkg/status"];
    
    // 1. 读取 dpkg 的 status 文件内容
    NSString *dpkgContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (dpkgContent) {
        // 2. 按照两个换行符分隔出每个 deb 包的信息
        NSArray *array = [dpkgContent componentsSeparatedByString:@"\n\n"];
        
        for (NSString *strDebInfo in array) {
            // 3. 拆分每个包的字段信息（按行拆分）
            NSArray *arrDebInfo = [strDebInfo componentsSeparatedByString:@"\n"];
            
            // 4. 取出第一行，应该是类似 "Package: com.xxx.xxx"
            NSString *strPackage = arrDebInfo[0];
            NSString *desPackage = [NSString stringWithFormat:@"Package: %@", bundleId];
            
            // 5. 比较包名是否匹配
            if ([strPackage hasPrefix:desPackage]) {
                
                return YES;
            }
        }
        return NO;
    } else {
        return NO;
    }
}


#pragma mark - 清除缓存
+(void)clearCache:(NSString *)identifier {
    
    Class LSApplicationWorkSpace = objc_getClass("LSApplicationWorkspace");
    NSObject *workspace = [LSApplicationWorkSpace performSelector:@selector(defaultWorkspace)];
    NSArray* (*appListSend)(id, SEL, id) = (NSArray*(*)(id,SEL,id))objc_msgSend;
    NSArray *appList = appListSend(workspace, @selector(applicationsOfType:), 0);
    for (id app in appList)
    {
        NSString *bundleID = [app performSelector:@selector(applicationIdentifier)];
        NSString *container = @"";
        NSURL *dataURL = [app performSelector:@selector(dataContainerURL)];
        if(dataURL) {
            container=[dataURL path];
        }
        if([identifier isEqualToString:@"*"]||[identifier isEqualToString:bundleID])
        {
            NSString *cachePath = [container stringByAppendingPathComponent:@"Library/Caches"];
            NSFileManager *fm=[NSFileManager defaultManager];
            NSArray *contents = [fm contentsOfDirectoryAtPath:cachePath error:nil];
            NSEnumerator *e = [contents objectEnumerator];
            NSString *filename;
            while ((filename = [e nextObject])) {
                [fm removeItemAtPath:[cachePath stringByAppendingPathComponent:filename] error:NULL];
            }
        }
    }
}


#pragma mark - 清除指定包名钥匙串
+(void)clearKeyChain:(NSString *)bundleID
{
    //    [self printKeyChain:bundleID];
    sqlite3 *database = NULL;
    if (sqlite3_open("/var/Keychains/keychain-2.db", &database) == SQLITE_OK)
    {
        NSString *query1 = [NSString stringWithFormat:@"DELETE FROM genp WHERE agrp LIKE '%%%@%%';", bundleID];
        int result1 = sqlite3_exec(database, [query1 UTF8String], NULL, NULL, NULL);
        if (result1 != SQLITE_OK) {
            LOGI(@"[genp] 删除失败: %s", sqlite3_errmsg(database));
        } else {
            LOGI(@"[genp] 删除成功");
        }
        
        NSString *query2 = [NSString stringWithFormat:@"DELETE FROM cert WHERE agrp LIKE '%%%@%%';", bundleID];
        int result2 = sqlite3_exec(database, [query2 UTF8String], NULL, NULL, NULL);
        if (result2 != SQLITE_OK) {
            LOGI(@"[cert] 删除失败: %s", sqlite3_errmsg(database));
        } else {
            LOGI(@"[cert] 删除成功");
        }
        
        NSString *query3 = [NSString stringWithFormat:@"DELETE FROM keys WHERE agrp LIKE '%%%@%%';", bundleID];
        int result3 = sqlite3_exec(database, [query3 UTF8String], NULL, NULL, NULL);
        if (result3 != SQLITE_OK) {
            LOGI(@"[keys] 删除失败: %s", sqlite3_errmsg(database));
        } else {
            LOGI(@"[keys] 删除成功");
        }
        
        NSString *query4 = [NSString stringWithFormat:@"DELETE FROM inet WHERE agrp LIKE '%%%@%%';", bundleID];
        int result4 = sqlite3_exec(database, [query4 UTF8String], NULL, NULL, NULL);
        if (result4 != SQLITE_OK) {
            LOGI(@"[inet] 删除失败: %s", sqlite3_errmsg(database));
        } else {
            LOGI(@"[inet] 删除成功");
        }
        
        sqlite3_close(database);
    } else {
        LOGI(@"打开钥匙串数据库失败: %s", sqlite3_errmsg(database));
    }
    //    [self printKeyChain:bundleID];
}

#pragma mark - 打印指定包名的钥匙串
+(void)printKeyChain:(NSString *)bundleID
{
    sqlite3 *database = NULL;
    if (sqlite3_open("/var/Keychains/keychain-2.db", &database) == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT rowid, * FROM genp WHERE agrp LIKE '%%%@%%';", bundleID];
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                int columnCount = sqlite3_column_count(stmt);
                NSMutableString *rowStr = [NSMutableString stringWithFormat:@"Row:\n"];
                for (int i = 0; i < columnCount; i++) {
                    const char *name = sqlite3_column_name(stmt, i);
                    const unsigned char *value = sqlite3_column_text(stmt, i);
                    if (name) {
                        [rowStr appendFormat:@"%s: %s\n", name, value ? (const char *)value : "NULL"];
                    }
                }
                LOGI(@"%@", rowStr);
            }
            sqlite3_finalize(stmt);
        } else {
            LOGI(@"Failed to prepare query.");
        }
        sqlite3_close(database);
    } else {
        LOGI(@"打开钥匙串数据库失败");
    }
}


#pragma mark - 启动App
+(BOOL)launch:(NSString *)bundleId {
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    // 判断是否有按照这个app
    BOOL isInstall = [workspace performSelector:@selector(applicationIsInstalled:) withObject:bundleId];
    
    if (isInstall) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleId];
        });
    }
    return isInstall;
}

#pragma mark - 获取指定包名的版本号
+(NSString *)getVersionForBundleIdentifier:(NSString *)bundleID {
    
    
    Class LSApplicationWorkSpace = objc_getClass("LSApplicationWorkspace");
    NSObject *workspace = [LSApplicationWorkSpace performSelector:@selector(defaultWorkspace)];
    for (id app in [workspace performSelector:@selector(allApplications)])
    {
        NSString *identifier = [app performSelector:@selector(applicationIdentifier)];
        if ([identifier isEqualToString:bundleID]) {
            NSString *version;
            
            NSURL *bundleURL = [app performSelector:@selector(bundleURL)];
            if (!bundleURL) {
                return @"1.0.0";
            }
            
            NSURL *infoPlistURL = [bundleURL URLByAppendingPathComponent:@"Info.plist"];
            NSString *infoPlistPath = [infoPlistURL path];
            
            NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
            if (!infoDict) {
                return @"1.0.0";
            }
            version = infoDict[@"CFBundleShortVersionString"];
            if (!version) {
                version = infoDict[@"CFBundleVersion"];
            }
            return version;
        }
    }
    return @"1.0.0";
}
@end


#pragma clang diagnostic pop

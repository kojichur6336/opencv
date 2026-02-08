//
//  YKCommand.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/18.
//

#import <dlfcn.h>
#import <notify.h>
#import "YKCommand.h"
#import "YKSBLogger.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "NSUserDefaults+Private.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define yk_loadMobileSafariSettingsBundle                           Acc65c1f5120d1f54bb4ba5ebd4f97902xb
#define yk_sharedSafariDeveloperSettingsController                  B5a2c02ddce4820d8953df8a76d5275aaee
#define yk_loadDisplayAndBrightnessSettingsFramework                Cf7ae82x6424b87aca44b00fc9b47ee9f86
#define yk_sharedDBSSettingsController                              Db8d062sb32d30253deb87a1e973183f522
#define yk_loadInternationalSettingsBundle                          E8e3df9786a2x8ae07f3db40b77d10d0b72
#define yk_loadSharingUIFramework                                   Faaae9652x96638443ee44d1ccd74e77a78
#define yk_sharedSFAirDropDiscoveryController                       Gcb82x40e789294ace3467f2ea812cf7865
#define yk_loadVPNPreferencesBundle                                 H6ca2x15ad2311affc8a1b17e3d959e0826


@interface SBWiFiManager : NSObject
+ (instancetype)sharedInstance;
- (void)setPowered:(BOOL)arg1;
- (void)setWiFiEnabled:(BOOL)arg1;
- (NSString *)currentNetworkName;
- (BOOL)wiFiEnabled;
@end


@interface BluetoothManager : NSObject
+ (instancetype)sharedInstance;
- (void)setEnabled:(BOOL)arg1;
- (BOOL)enabled;
@end


@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (void)remoteLock:(BOOL)arg1;
- (BOOL)isUILocked;
- (void)attemptUnlockWithPasscode:(NSString *)arg1;
- (void)attemptUnlockWithPasscode:(NSString *)arg1 finishUIUnlock:(BOOL)arg2 completion:(/*^block*/ id)arg3;
@end


@interface SBBacklightController : NSObject
@property (nonatomic, readonly) BOOL screenIsOn;
@property (nonatomic, readonly) BOOL screenIsDim;
- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1;
+ (instancetype)sharedInstance;
- (void)setBacklightFactor:(float)arg1 source:(long long)arg2;
- (double)backlightFactor;
@end


@interface SBOrientationLockManager : NSObject
+ (instancetype)sharedInstance;
- (void)lock;
- (void)unlock;
- (BOOL)isLocked;
- (BOOL)isUserLocked;
- (BOOL)isEffectivelyLocked;
@end


@interface SBAirplaneModeController : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isInAirplaneMode;
- (void)setInAirplaneMode:(BOOL)arg1;
@end


@interface SBRingerControl : NSObject
- (float)volume;
- (void)setVolume:(float)arg1;
- (BOOL)isRingerMuted;
- (void)setRingerMuted:(BOOL)arg1;
- (BOOL)lastSavedRingerMutedState;
- (void)activateRingerHUDFromMuteSwitch:(int)arg1;
- (void)activateRingerHUDForVolumeChangeWithInitialVolume:(float)arg1;
- (void)setVolume:(float)arg1 forKeyPress:(BOOL)arg2;
- (void)_softMuteChanged:(id)arg1;
- (void)activateRingerHUD:(int)arg1 withInitialVolume:(float)arg2 fromSource:(unsigned long long)arg3;
- (void)hideRingerHUDIfVisible;
- (void)toggleRingerMute;
@end

@interface SBVolumeControl : NSObject
+ (instancetype)sharedInstance;
- (void)increaseVolume;
- (void)decreaseVolume;
- (float)volumeStepUp;
- (float)volumeStepDown;
- (void)setVolume:(float)arg1 forCategory:(id)arg2;
- (void)setActiveCategoryVolume:(float)arg1;
- (void)_presentVolumeHUDWithVolume:(float)arg1;
- (float)_effectiveVolume;
- (void)_updateEffectiveVolume:(float)arg1;
@end


@interface SafariDeveloperSettingsController : NSObject
- (void)setRemoteInspectorEnabled:(NSNumber *)arg1 specifier:(id)arg2;
- (NSNumber *)remoteInspectorEnabled:(id)arg1;
- (void)setRemoteAutomationEnabled:(NSNumber *)arg1 specifier:(id)arg2;
- (NSNumber *)_remoteAutomationEnabled:(id)arg1;
- (void)_setRemoteInspectorEnabled:(BOOL)arg1;
- (void)_setRemoteAutomationEnabled:(BOOL)arg1;
- (BOOL)isJavaScriptRestricted:(id)arg1;
- (NSNumber *)isJavaScriptEnabled:(id)arg1;
@end

@interface UISUserInterfaceStyleMode : NSObject
@property (nonatomic, assign) UIUserInterfaceStyle modeValue;
@end

@interface DBSSettingsController : NSObject
- (NSNumber *)screenLock:(id)arg1;
- (void)setScreenLock:(NSNumber *)arg1 specifier:(id)arg2;
- (NSNumber *)getAutomaticAppearanceEnabledForSpecifier:(id)arg1;
- (void)setAutomaticAppearanceEnabled:(NSNumber *)arg1 forSpecifier:(id)arg2;
- (UISUserInterfaceStyleMode *)_styleMode;
- (void)_updateDeviceAppearanceToNewInterfaceStyle:(UIUserInterfaceStyle)arg1;  // 1 light 2 dark
- (NSNumber *)boldTextEnabledForSpecifier:(id)arg1 ;
- (void)setBoldTextEnabled:(NSNumber *)arg1 specifier:(id)arg2 ;
@end


@interface SBRestartManager : NSObject
- (void)shutdownForReason:(id)arg1;
- (void)rebootForReason:(id)arg1;
@end

@interface SpringBoard : UIApplication
+ (SpringBoard *)sharedApplication;
- (void)beginIgnoringInteractionEvents;
- (void)endIgnoringInteractionEvents;
- (void)takeScreenshot;
- (SBRestartManager *)restartManager;
- (void)suspend;
@end


@interface InternationalSettingsController : NSObject
+ (void)setPreferredLanguages:(NSArray <NSString *> *)arg1;
+ (void)setLanguage:(NSString *)arg1;
+ (void)setCurrentLanguage:(NSString *)arg1;
- (void)setLocaleOnly:(NSString *)arg1;
+ (void)syncPreferencesAndPostNotificationForLanguageChange;
@end

@interface SFAirDropDiscoveryController : NSObject
- (NSInteger)discoverableMode;  // 0: 接收关闭 1: 仅限联系人 2: 所有人
- (void)setDiscoverableMode:(NSInteger)arg1 ;
@end


@interface VPNConnectionStore : NSObject
@property (retain) NSArray * configurations;
@property (assign) unsigned vpnServiceCountDirty;
@property (assign) unsigned vpnServiceCount;
+(id)sharedInstance;
-(BOOL)createVPNWithOptions:(id)arg1;
-(BOOL)deleteVPNWithServiceID:(id)arg1;
-(void)setActiveVPNID:(id)arg1 withGrade:(unsigned long long)arg2;
@end

@interface NEConfiguration : NSObject
@property (readonly) NSUUID * identifier;
@property (copy) NSString * application;
@property (copy) NSString * name;
@property (copy) NSString * applicationName;
@property (copy) NSString * applicationIdentifier;
@end

NS_INLINE
NSString *yk_InternationalSettingsExtractLanguageCode(NSString *languageCode) {
    languageCode = [languageCode stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    if ([languageCode hasPrefix:@"zh"]) {
        if ([languageCode hasPrefix:@"zh-Hans"] || [languageCode hasPrefix:@"zh-CN"])
            return @"zh-Hans";
        else if ([languageCode isEqualToString:@"zh-Hant-HK"] || [languageCode hasPrefix:@"zh-HK"])
            return @"zh-Hant-HK";
        else
            return @"zh-Hant";
    } else if ([languageCode hasPrefix:@"en"]) {
        if ([languageCode isEqualToString:@"en-US"])
            return @"en-US";
        else if ([languageCode isEqualToString:@"en-GB"])
            return @"en-GB";
        else if ([languageCode isEqualToString:@"en-AU"])
            return @"en-AU";
        else if ([languageCode isEqualToString:@"en-IN"])
            return @"en-IN";
        else
            return @"en";
    } else if ([languageCode hasPrefix:@"es"]) {
        if ([languageCode isEqualToString:@"es-MX"])
            return @"es-MX";
        else if ([languageCode isEqualToString:@"es-US"])
            return @"es-US";
        else if ([languageCode isEqualToString:@"es-419"])
            return @"es-419";
        else
            return @"es";
    } else if ([languageCode hasPrefix:@"fr"]) {
        if ([languageCode isEqualToString:@"fr-CA"])
            return @"fr-CA";
        else
            return @"fr";
    } else if ([languageCode hasPrefix:@"ja"]) {
        return @"ja";
    } else if ([languageCode hasPrefix:@"de"]) {
        return @"de";
    } else if ([languageCode hasPrefix:@"ru"]) {
        return @"ru";
    } else if ([languageCode hasPrefix:@"pt"]) {
        if ([languageCode isEqualToString:@"pt-BR"])
            return @"pr-BR";
        else
            return @"pt-PT";
    } else if ([languageCode hasPrefix:@"it"]) {
        return @"it";
    } else if ([languageCode hasPrefix:@"ko"]) {
        return @"ko";
    } else if ([languageCode hasPrefix:@"tr"]) {
        return @"tr";
    } else if ([languageCode hasPrefix:@"nl"]) {
        return @"nl";
    } else if ([languageCode hasPrefix:@"ar"]) {
        return @"ar";
    } else if ([languageCode hasPrefix:@"th"]) {
        return @"th";
    } else if ([languageCode hasPrefix:@"sv"]) {
        return @"sv";
    } else if ([languageCode hasPrefix:@"da"]) {
        return @"da";
    } else if ([languageCode hasPrefix:@"vi"]) {
        return @"vi";
    } else if ([languageCode hasPrefix:@"pl"]) {
        return @"pl";
    } else if ([languageCode hasPrefix:@"fi"]) {
        return @"fi";
    } else if ([languageCode hasPrefix:@"id"]) {
        return @"id";
    } else if ([languageCode hasPrefix:@"he"]) {
        return @"he";
    } else if ([languageCode hasPrefix:@"el"]) {
        return @"el";
    } else if ([languageCode hasPrefix:@"ro"]) {
        return @"ro";
    } else if ([languageCode hasPrefix:@"hu"]) {
        return @"hu";
    } else if ([languageCode hasPrefix:@"cs"]) {
        return @"cs";
    } else if ([languageCode hasPrefix:@"sk"]) {
        return @"sk";
    } else if ([languageCode hasPrefix:@"uk"]) {
        return @"uk";
    } else if ([languageCode hasPrefix:@"hr"]) {
        return @"hr";
    } else if ([languageCode hasPrefix:@"ms"]) {
        return @"ms";
    }
    return @"en";
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"



@implementation YKCommand

#pragma mark - 回到首页
+(void)yk_homeScreen {
    
    Class SpringBoard = objc_getClass("SpringBoard");
    
    if (SpringBoard) {
        
        SEL sharedApplication = @selector(sharedApplication);
        id instance = ((id(*)(id,SEL))objc_msgSend)((id)SpringBoard,sharedApplication);
        
        if (@available(iOS 15.0, *)) {
            SEL simulateHomeButtonPressWithCompletion = @selector(_simulateHomeButtonPressWithCompletion:);
            id completionBlock = ^(BOOL success) {};
            if (instance && [instance respondsToSelector:simulateHomeButtonPressWithCompletion]) {
                ((void(*)(id,SEL,id))objc_msgSend)(instance, simulateHomeButtonPressWithCompletion, completionBlock);
            }
        } else {
            SEL simulateHomeButtonPress = @selector(_simulateHomeButtonPress);
            if (instance && [instance respondsToSelector:simulateHomeButtonPress]) {
                ((void(*)(id,SEL))objc_msgSend)(instance,simulateHomeButtonPress);
            }
        }
    }
}

#pragma mark - 启动App
+(BOOL)yk_launch:(NSString *)bundleId {
    
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

#pragma mark - 获取前台执行的App
+(NSString *)yk_frontAppBID {
    
    Class SpringBoard = objc_getClass("SpringBoard");
    if (SpringBoard) {
        SEL sharedApplication = @selector(sharedApplication);
        id instance = ((id(*)(id,SEL))objc_msgSend)((id)SpringBoard,sharedApplication);
        SEL _accessibilityFrontMostApplication = @selector(_accessibilityFrontMostApplication);
        if (instance && [instance respondsToSelector:_accessibilityFrontMostApplication]) {
            id applicationInfo = ((id(*)(id,SEL))objc_msgSend)(instance,_accessibilityFrontMostApplication);//SBApplication
            if (applicationInfo != nil) {
                SEL bundleIdentifier = @selector(bundleIdentifier);
                if ([applicationInfo respondsToSelector:bundleIdentifier]) {
                    NSString *bid = ((id(*)(id,SEL))objc_msgSend)(applicationInfo, bundleIdentifier);
                    return bid;
                }
            }
        }
    }
    return @"com.apple.springboard";
}

#pragma mark - 卸载App
+(BOOL)yk_uninstallApp:(NSString *)bundleId {
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    // 判断是否有按照这个app
    BOOL isInstall = [workspace performSelector:@selector(applicationIsInstalled:) withObject:bundleId];
    if (isInstall) {
        @try {
            BOOL (*uninstallapp)(id, SEL, id, id) = (BOOL(*)(id,SEL,id,id))objc_msgSend;
            uninstallapp(workspace, @selector(uninstallApplication:withOptions:),bundleId, nil);
        } @catch (NSException *e) {
        }
        return YES;
    } else {
        LOGI(@"未安装此App");
        return NO;
    }
}

#pragma mark - 获取WIFI Mac 地址
+(NSString *)yk_wifiMacAddress {
    
    // 动态获取类
    Class AADeviceInfoClass = objc_getClass("AADeviceInfo");
    if (!AADeviceInfoClass) {
        return @"";
    }
    
    // 创建实例
    id deviceInfoInstance = [[AADeviceInfoClass alloc] init];
    if (!deviceInfoInstance) {
        return @"";
    }
    
    // 动态调用方法
    SEL wifiMacAddressSelector = NSSelectorFromString(@"wifiMacAddress");
    if (![deviceInfoInstance respondsToSelector:wifiMacAddressSelector]) {
        return @"";
    }
    
    // 获取Mac地址
    IMP imp = [deviceInfoInstance methodForSelector:wifiMacAddressSelector];
    NSString *(*func)(id, SEL) = (void *)imp;
    NSString *serialNumber = func(deviceInfoInstance, wifiMacAddressSelector);
    return serialNumber ?: @"";
}

#pragma mark - 获取唯一标识
+(NSString *)yk_udid {
    typedef CFPropertyListRef(*MGCopyAnswerFunc)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    MGCopyAnswerFunc mgcopy = dlsym(gestalt, "MGCopyAnswer");
    CFStringRef UDID = mgcopy(CFSTR("UniqueDeviceID"));
    return (__bridge NSString * _Nonnull)(UDID);
}


#pragma mark - 杀掉所有app
+(void)yk_killAllApp {
    
    if (@available(iOS 16.0, *)) {
        
        BOOL (*updateFunc)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
        id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
        Class SBMainSwitcherControllerCoordinator = objc_getClass("SBMainSwitcherControllerCoordinator");
        SEL sharedInstance = @selector(sharedInstance);
        id instance = msgSend(SBMainSwitcherControllerCoordinator,sharedInstance);
        
        NSArray *array;
        if ([instance respondsToSelector:@selector(recentAppLayouts)]) {
            array = msgSend(instance, @selector(recentAppLayouts));
        }
        
        for (id layout in array) {
            
            void (*quitFunc)(id, SEL, id, long long) = (void(*)(id, SEL, id, long long))objc_msgSend;
            if ([instance respondsToSelector:@selector(_removeAppLayout:forReason:)]) {
                quitFunc(instance, @selector(_removeAppLayout:forReason:), layout, 0);
            }
        }
        
        /// 1秒后执行刷新操作
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            updateFunc(instance, @selector(handleHomeButtonPress));
        });
        
    } else {
        
        BOOL (*updateFunc)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
        id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
        Class SBMainSwitcherViewController = objc_getClass("SBMainSwitcherViewController");
        SEL sharedInstance = @selector(sharedInstance);
        id instance = msgSend(SBMainSwitcherViewController,sharedInstance);
        
        NSArray *array;
        if ([instance respondsToSelector:@selector(recentAppLayouts)]) {
            array = msgSend(instance, @selector(recentAppLayouts));
        } else if ([instance respondsToSelector:@selector(appLayouts)]) {
            array = msgSend(instance, @selector(appLayouts));
        }
        
        for (id layout in array) {
            
            void (*quitFunc)(id, SEL, id, long long) = (void(*)(id, SEL, id, long long))objc_msgSend;
            if ([instance respondsToSelector:@selector(_quitAppsRepresentedByAppLayout:forReason:)]) {
                quitFunc(instance, @selector(_quitAppsRepresentedByAppLayout:forReason:), layout, 0);
            } else if ([instance respondsToSelector:@selector(_removeAppLayout:forReason:)]) {
                quitFunc(instance, @selector(_removeAppLayout:forReason:), layout, 0);
            } else if ([instance respondsToSelector:@selector(_deleteAppLayout:forReason:)]) {
                quitFunc(instance, @selector(_deleteAppLayout:forReason:), layout, 0);
            }
        }
        
        /// 1秒后执行刷新操作
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            updateFunc(instance, @selector(handleHomeButtonSinglePressUp));
        });
    }
}

#pragma mark - 杀掉App
+(void)yk_killAppWithBid:(NSString *)bundleId flag:(int)flag {
    
    BOOL isAllKill = [bundleId isEqualToString: @"*"] ? true : false;
    if (flag == 0)
    {
        id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
        Class SBApplicationController = objc_getClass("SBApplicationController");
        SEL sharedInstance = @selector(sharedInstance);
        id instance = msgSend(SBApplicationController,sharedInstance);
        NSArray *sbApps = msgSend(instance, @selector(allApplications));
        for (id app in sbApps) {
            
            NSString *bundleIdentifier = msgSend(app, @selector(bundleIdentifier));
            if ([bundleIdentifier isEqualToString:bundleId] || isAllKill) {
                
                if ([app respondsToSelector:@selector(processState)]) {
                    
                    id SBApplicationProcessState = msgSend(app, @selector(processState));
                    if (SBApplicationProcessState) {
                        SEL isRunningSelector = @selector(isRunning);
                        if ([SBApplicationProcessState respondsToSelector:isRunningSelector]) {
                            BOOL (*msgSendIsRunning)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
                            BOOL sbAppIsRunning = msgSendIsRunning(SBApplicationProcessState, isRunningSelector);
                            if (sbAppIsRunning) {
                                int (*pidFunc)(id, SEL) = (int (*)(id, SEL))objc_msgSend;
                                int pid = pidFunc(SBApplicationProcessState, @selector(pid));
                                [self yk_killProcessWithPID:pid];
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
    else
    {
        
        if (@available(iOS 16.0, *)) {
            
            BOOL (*updateFunc)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
            id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
            Class SBMainSwitcherControllerCoordinator = objc_getClass("SBMainSwitcherControllerCoordinator");
            SEL sharedInstance = @selector(sharedInstance);
            id instance = msgSend(SBMainSwitcherControllerCoordinator,sharedInstance);
            
            NSArray *array;
            if ([instance respondsToSelector:@selector(recentAppLayouts)]) {
                array = msgSend(instance, @selector(recentAppLayouts));
            }
            
            for (id layout in array) {
                
                NSArray *items = msgSend(layout, @selector(allItems));
                id SBDisplayItem = items[0];
                NSString *bundleIdentifier;
                if ([SBDisplayItem respondsToSelector:@selector(bundleIdentifier)]) {
                    bundleIdentifier = [SBDisplayItem performSelector:@selector(bundleIdentifier)];
                }
                
                if ([bundleIdentifier isEqualToString:bundleId] || isAllKill) {
                    
                    void (*quitFunc)(id, SEL, id, long long) = (void(*)(id, SEL, id, long long))objc_msgSend;
                    if ([instance respondsToSelector:@selector(_removeAppLayout:forReason:)]) {
                        quitFunc(instance, @selector(_removeAppLayout:forReason:), layout, 0);
                    }
                    if (!isAllKill)
                    {
                        break;
                    }
                }
            }
            
            /// 1秒后执行刷新操作
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                updateFunc(instance, @selector(handleHomeButtonPress));
            });
            
        } else {
            
            BOOL (*updateFunc)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
            id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
            Class SBMainSwitcherViewController = objc_getClass("SBMainSwitcherViewController");
            SEL sharedInstance = @selector(sharedInstance);
            id instance = msgSend(SBMainSwitcherViewController,sharedInstance);
            
            NSArray *array;
            if ([instance respondsToSelector:@selector(recentAppLayouts)]) {
                array = msgSend(instance, @selector(recentAppLayouts));
            } else if ([instance respondsToSelector:@selector(appLayouts)]) {
                array = msgSend(instance, @selector(appLayouts));
            }
            
            for (id layout in array) {
                NSArray *items = msgSend(layout, @selector(allItems));
                id SBDisplayItem = items[0];
                
                NSString *bundleIdentifier;
                if ([SBDisplayItem respondsToSelector:@selector(bundleIdentifier)]) {
                    bundleIdentifier = [SBDisplayItem performSelector:@selector(bundleIdentifier)];
                } else if ([SBDisplayItem respondsToSelector:@selector(displayIdentifier)]) {
                    bundleIdentifier = [SBDisplayItem performSelector:@selector(displayIdentifier)];
                }
                
                if ([bundleIdentifier isEqualToString:bundleId] || isAllKill) {
                    void (*quitFunc)(id, SEL, id, long long) = (void(*)(id, SEL, id, long long))objc_msgSend;
                    if ([instance respondsToSelector:@selector(_quitAppsRepresentedByAppLayout:forReason:)]) {
                        quitFunc(instance, @selector(_quitAppsRepresentedByAppLayout:forReason:), layout, 0);
                    } else if ([instance respondsToSelector:@selector(_removeAppLayout:forReason:)]) {
                        quitFunc(instance, @selector(_removeAppLayout:forReason:), layout, 0);
                    } else if ([instance respondsToSelector:@selector(_deleteAppLayout:forReason:)]) {
                        quitFunc(instance, @selector(_deleteAppLayout:forReason:), layout, 0);
                    }
                    if (!isAllKill)
                    {
                        break;
                    }
                }
            }
            
            /// 1秒后执行刷新操作
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                updateFunc(instance, @selector(handleHomeButtonSinglePressUp));
            });
        }
    }
}

#pragma mark - 关闭进程
+(BOOL)yk_killProcessWithPID:(pid_t)pid {
    
    int status = kill(pid, SIGKILL);
    if (status == 0) {
        LOGI(@"成功终止进程 %d", pid);
        return YES;
    } else {
        LOGI(@"终止进程 %d 失败: %s", pid, strerror(errno));
        return NO;
    }
}


#pragma mark - 设置设备名称
+(BOOL)yk_setDeviceName:(NSString *)name {
    
    BOOL result = false;
    
    typedef void(*setDeviceNameFunc)(NSString*);
    void *frameworkLibrary = dlopen("/System/Library/PrivateFrameworks/Preferences.framework/Preferences", RTLD_GLOBAL | RTLD_LAZY);
    setDeviceNameFunc setName = dlsym(frameworkLibrary, "SetDeviceName");
    if (setName) {
        setName(name);
        result = true;
    }
    return result;
}

#pragma mark - 显示控制中心
+(void)yk_showCenterController {
    
    // 获取 SBControlCenterController 类
    Class SBControlCenterControllerClass = NSClassFromString(@"SBControlCenterController");
    
    // 确保类存在
    if (SBControlCenterControllerClass) {
        // 获取 sharedInstance 方法的选择器
        SEL sharedInstanceSelector = @selector(sharedInstance);
        
        // 获取 sharedInstance 方法并调用
        id controlCenterController = ((id (*)(id, SEL))objc_msgSend)(SBControlCenterControllerClass, sharedInstanceSelector);
        
        if (controlCenterController) {
            
            // 获取 isVisible 方法的选择器
            SEL isVisibleSelector = @selector(isVisible);
            
            // 动态调用 isVisible 方法判断控制中心是否可见
            _Bool isVisible = ((BOOL (*)(id, SEL))objc_msgSend)(controlCenterController, isVisibleSelector);
            
            if (isVisible) {
                // 如果控制中心可见，调用 dismissAnimated:completion:
                SEL dismissSelector = @selector(dismissAnimated:completion:);
                ((void (*)(id, SEL, BOOL, id))objc_msgSend)(controlCenterController, dismissSelector, YES, nil);
            } else {
                
                // 获取 presentAnimated: 方法的选择器
                SEL presentSelector = @selector(presentAnimated:completion:);
                
                // 动态调用 presentAnimated:completion: 方法
                ((void (*)(id, SEL, BOOL, id))objc_msgSend)(controlCenterController, presentSelector, YES, nil);
            }
        } else {
            LOGI(@"无法获取 SBControlCenterController 的 sharedInstance");
        }
    } else {
        LOGI(@"无法找到 SBControlCenterController 类");
    }
}


#pragma mark - 打开后台管理进程
+(void)yk_appSwitcher {
    
    Class sbUIControllerClass = objc_getClass("SBUIController");
    SEL sharedInstance = @selector(sharedInstance);
    id (*msgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
    id sbUISharedInstance = msgSend(sbUIControllerClass, sharedInstance);
    msgSend(sbUISharedInstance,@selector(handleHomeButtonDoublePressDown));
}


#pragma mark - 设置WIFI
+(void)yk_setWifiEnable:(BOOL)enabled {
    
    SBWiFiManager *mgr = [objc_getClass("SBWiFiManager") sharedInstance];
    [mgr setPowered:YES];
    [mgr setWiFiEnabled:enabled];
}

#pragma mark - 获取WIFI状态
+(BOOL)yk_isWiFiEnabled {
    
    SBWiFiManager *mgr = [objc_getClass("SBWiFiManager") sharedInstance];
    return [mgr wiFiEnabled];
}


#pragma mark - 蜂窝网络开关
typedef void (*CTCellularDataPlanSetIsEnabled)(BOOL);
+(void)yk_setCellularDataEnable:(BOOL)enabled {
    
    CTCellularDataPlanSetIsEnabled CTCellularDataPlanSetIsEnabledPtr = NULL;
    CTCellularDataPlanSetIsEnabledPtr = (CTCellularDataPlanSetIsEnabled)dlsym(RTLD_DEFAULT,"CTCellularDataPlanSetIsEnabled");
    CTCellularDataPlanSetIsEnabledPtr(enabled);
}

#pragma mark - 获取蜂窝开关
+(BOOL)yk_isCellularDataEnable {
    
    typedef Boolean (*CTCellularDataPlanGetIsEnabledFunc)(void);
    CTCellularDataPlanGetIsEnabledFunc getEnabledPtr = (CTCellularDataPlanGetIsEnabledFunc)dlsym(RTLD_DEFAULT, "CTCellularDataPlanGetIsEnabled");
    if (getEnabledPtr) {
        Boolean enabled = getEnabledPtr();
        return (BOOL)enabled;
    }
    return NO;
}


#pragma mark - 静音切换
+(void)yk_volumeToggleMute {
    
    void (*setVolumeLevelFun)(id,SEL) = (void(*)(id,SEL))objc_msgSend;
    if (@available(iOS 13.0, *)) {
        
        Class sbUIControllerClass = objc_getClass("SBUIController");
        if ([sbUIControllerClass respondsToSelector:@selector(sharedInstance)]) {
            NSObject *sbUIController = [sbUIControllerClass performSelector:@selector(sharedInstance)];
            NSObject *volumeControl = [sbUIController valueForKey:@"_volumeControl"];
            setVolumeLevelFun(volumeControl,@selector(toggleMute));
        }
    } else {
        
        Class volumeClass = objc_getClass("VolumeControl");
        NSObject *shareInstance = [volumeClass performSelector:@selector(sharedVolumeControl)];
        if (shareInstance) {
            setVolumeLevelFun(shareInstance,@selector(toggleMute));
        }
    }
}


#pragma mark - 设置蓝牙
+(void)yk_setBluetoothEnable:(BOOL)enabled {
    
    Class bluetoothCls = objc_getClass("BluetoothManager");
    [[bluetoothCls sharedInstance] setEnabled:enabled];
}

/// 获取蓝牙是否开启
+(BOOL)yk_isBluetoothEnabled {
    
    Class bluetoothCls = objc_getClass("BluetoothManager");
    return [[bluetoothCls sharedInstance] enabled];
}


#pragma mark - Home+音量键 截图
+(void)yk_screenshot {
    
    Class SpringBoard = objc_getClass("SpringBoard");
    
    if (SpringBoard) {
        
        SEL sharedApplication = @selector(sharedApplication);
        id instance = ((id(*)(id,SEL))objc_msgSend)((id)SpringBoard,sharedApplication);
        
        SEL sbScreenshotManager = @selector(screenshotManager);
        if ([instance respondsToSelector:sbScreenshotManager]) {
            
            id manager = ((id(*)(id,SEL))objc_msgSend)(instance,sbScreenshotManager);//SBScreenshotManager
            SEL saveScreenshotsWithCompletion = @selector(saveScreenshotsWithCompletion:);
            if ([manager respondsToSelector:saveScreenshotsWithCompletion]) {
                ((void(*)(id,SEL,id))objc_msgSend)(manager, saveScreenshotsWithCompletion, nil);
            }
        }
    }
}


#pragma mark - 静音模式设置
OBJC_EXTERN SBRingerControl *yk_globalRingerControl;
+(void)yk_setRingerEnabled:(BOOL)enabled
{
    if (enabled) {
        [yk_globalRingerControl setRingerMuted:YES];
        [yk_globalRingerControl activateRingerHUDFromMuteSwitch:0];
    } else {
        [yk_globalRingerControl setRingerMuted:NO];
        [yk_globalRingerControl activateRingerHUDFromMuteSwitch:1];
    }
}


#pragma mark - 获取App数据路径
+(NSString *)yk_getAppDataPath:(NSString *)identifier {
    
    
    // 判断是否存在 LSBundleProxy 类
    Class LSBundleProxy = objc_getClass("LSBundleProxy");
    if (!LSBundleProxy) {
        LOGI(@"LSBundleProxy not found.");
        return @"";
    }
    
    // 判断是否响应 +bundleProxyForIdentifier:
    if (![LSBundleProxy respondsToSelector:@selector(bundleProxyForIdentifier:)]) {
        LOGI(@"bundleProxyForIdentifier: not available.");
        return @"";
    }
    
    // 动态调用类方法 bundleProxyForIdentifier:
    id bundleProxy = ((id (*)(id, SEL, id))objc_msgSend)(LSBundleProxy, @selector(bundleProxyForIdentifier:), identifier);
    
    if (bundleProxy && [bundleProxy respondsToSelector:@selector(dataContainerURL)]) {
        NSURL *url = ((NSURL *(*)(id, SEL))objc_msgSend)(bundleProxy, @selector(dataContainerURL));
        if (url) {
            return [url path];
        }
    }
    return @"";
}

#pragma mark - 获取App安装包路径
+(NSString *)yk_getAppBundlePath:(NSString *)identifier
{
    Class LSApplicationWorkSpace = objc_getClass("LSApplicationWorkspace");
    NSObject *workspace = [LSApplicationWorkSpace performSelector:@selector(defaultWorkspace)];
    NSArray* (*appListSend)(id, SEL, id) = (NSArray*(*)(id,SEL,id))objc_msgSend;
    NSArray *appList = appListSend(workspace, @selector(applicationsOfType:), 0);
    for (id app in appList)
    {
        NSString *bundleID = [app performSelector:@selector(applicationIdentifier)];
        NSString *container = @"";
        NSURL *bundleURL = [app performSelector:@selector(bundleURL)];
        if(bundleURL) {
            container = [bundleURL path];
        }
        if([identifier isEqualToString:@"*"]||[identifier isEqualToString:bundleID])
        {
            return container;
        }
    }
    return @"";
}

#pragma mark - 获取App共享数据路径
+(NSString *)yk_getGroupContainerPath:(NSString *)identifier {
    
    // 1. 拿到 LSBundleProxy 类
    Class LSBundleProxy = objc_getClass("LSBundleProxy");
    if (!LSBundleProxy) {
        LOGI(@"❌ 找不到 LSBundleProxy");
        return @"";
    }
    
    // 2. 获取 +bundleProxyForIdentifier: 方法
    SEL selProxy = NSSelectorFromString(@"bundleProxyForIdentifier:");
    id proxy = ((id (*)(Class, SEL, NSString *))objc_msgSend)(LSBundleProxy, selProxy, identifier);
    
    if (!proxy) {
        LOGI(@"❌ 找不到 Bundle Proxy for %@", identifier);
        return @"";
    }
    
    // 3. 获取 -groupContainerURLs 方法
    SEL selGroups = NSSelectorFromString(@"groupContainerURLs");
    NSDictionary *groupDict = ((NSDictionary *(*)(id, SEL))objc_msgSend)(proxy, selGroups);
    
    // 4. 遍历所有 groupContainerURLs，拼接成字符串
    NSMutableArray *paths = [NSMutableArray array];
    for (NSString *groupId in groupDict)
    {
        NSURL *url = groupDict[groupId];
        if (url) {
            [paths addObject:url.path];  // ✅ 这里返回的是纯路径，没有 file://
        }
    }
    
    // 5. 用逗号分隔返回
    NSString *result = [paths componentsJoinedByString:@","];
    return result;
}

#pragma mark - 锁定屏幕
+(void)yk_lockScreen {
    
    Class mgrCls = objc_getClass("SBLockScreenManager");
    [[mgrCls sharedInstance] remoteLock:YES];
}


#pragma mark - 解锁屏幕
+(void)yk_unLockScreen:(NSString *)passcode
{
    {
        // --- 第一步：强制点亮屏幕背光 ---
        // 获取 SpringBoard 内部负责背光控制的类 SBBacklightController
        Class ctrl = objc_getClass("SBBacklightController");
        
        // 获取该控制器的单例对象
        id backlightCtrl = [ctrl sharedInstance];
        
        // 检查该对象是否能响应点亮屏幕的私有方法
        if ([backlightCtrl respondsToSelector:@selector(turnOnScreenFullyWithBacklightSource:)]) {
            // 强制完全点亮屏幕。参数 1 通常代表“背光触发源”为手动触发或系统触发
            [backlightCtrl turnOnScreenFullyWithBacklightSource:1];
        }
    }
    
    {
        // --- 第二步：调用锁屏管理器尝试密码解锁 ---
        // 获取 SpringBoard 内部负责锁屏管理的类 SBLockScreenManager
        Class manager = objc_getClass("SBLockScreenManager");
        
        // 获取锁屏管理器的单例对象
        id screenManager = [manager sharedInstance];
        
        // 适配不同 iOS 版本的私有 API（苹果经常在更新中修改这些方法的参数）
        if ([screenManager respondsToSelector:@selector(attemptUnlockWithPasscode:finishUIUnlock:completion:)]) {
            // 现代 iOS 版本的接口：
            // attemptUnlockWithPasscode: 传入用户密码
            // finishUIUnlock: YES 表示解锁成功后完成进入主界面的动画过渡
            // completion: 完成后的回调（此处传 nil）
            [screenManager attemptUnlockWithPasscode:passcode finishUIUnlock:YES completion:nil];
        } else {
            // 旧版 iOS（通常是 iOS 9 及以下）的简化版解锁接口
            [screenManager attemptUnlockWithPasscode:passcode];
        }
    }
}

#pragma mark - 是否锁屏
+(BOOL)yk_isScreenLocked {
    Class mgrCls = objc_getClass("SBLockScreenManager");
    return [[mgrCls sharedInstance] isUILocked];
}

#pragma mark - 锁定屏幕旋转
+(void)yk_lockOrientation {
    
    Class manager = objc_getClass("SBOrientationLockManager");
    SBOrientationLockManager *lockMgr = [manager sharedInstance];
    [lockMgr lock];
}

#pragma mark - 解除屏幕旋转锁定
+(void)yk_unlockOrientation {
    
    Class manager = objc_getClass("SBOrientationLockManager");
    SBOrientationLockManager *lockMgr = [manager sharedInstance];
    [lockMgr unlock];
}

#pragma mark - 查询当前是否已经锁定了屏幕旋转
+(BOOL)yk_isOrientationLocked {
    
    Class manager = objc_getClass("SBOrientationLockManager");
    SBOrientationLockManager *lockMgr = [manager sharedInstance];
    
    if ([lockMgr respondsToSelector:@selector(isLocked)]) {
        return [lockMgr isLocked];
    } else if ([lockMgr respondsToSelector:@selector(isUserLocked)]) {
        return [lockMgr isUserLocked];
    } else {
        return [lockMgr isEffectivelyLocked];
    }
}

#pragma mark - 震动
+(void)yk_vibrate {
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - 设置飞行模式
+(void)yk_setAirplaneMode:(BOOL)enabled {
    
    Class airplaneCls = objc_getClass("SBAirplaneModeController");
    [[airplaneCls sharedInstance] setInAirplaneMode:enabled];
}

#pragma mark - 获取当前飞行模式的状态
+(BOOL)yk_isAirplaneEnabled {
    
    Class airplaneCls = objc_getClass("SBAirplaneModeController");
    return [[airplaneCls sharedInstance] isInAirplaneMode];
}

#pragma mark - 设置闪光灯
+(void)yk_setflashEnable:(BOOL)enabled yk_level:(double)level {
    
    if (enabled) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasFlash]) {
            [device lockForConfiguration:nil];
            [device setTorchModeOnWithLevel:(float)level error:nil];
            [device unlockForConfiguration];
        }
    } else {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasFlash]) {
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
}

#pragma mark - 获取是否开启闪光灯
+(BOOL)yk_isFlashEnabled {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasFlash]) {
        [device lockForConfiguration:nil];
        AVCaptureTorchMode torchMode = [device torchMode];
        [device unlockForConfiguration];
        return torchMode == AVCaptureTorchModeOn;
    } else {
        return NO;
    }
}

#pragma mark - 设置当前音量
+(void)yk_setCurrentVolume:(float)volume {
    
    if (volume < 0.0f) volume = 0.0f;
    if (volume > 1.0f) volume = 1.0f;
    void (*setVolumeLevelFun)(id,SEL,float) = (void(*)(id,SEL,float))objc_msgSend;
    if (@available(iOS 13.0, *)) {
        
        Class sbUIControllerClass = objc_getClass("SBUIController");
        if ([sbUIControllerClass respondsToSelector:@selector(sharedInstance)]) {
            NSObject *sbUIController = [sbUIControllerClass performSelector:@selector(sharedInstance)];
            NSObject *volumeControl = [sbUIController valueForKey:@"_volumeControl"];
            setVolumeLevelFun(volumeControl, @selector(_setMediaVolumeForIAP:), volume);
        }
    } else {
        
        Class volumeClass = objc_getClass("VolumeControl");
        NSObject *shareInstance = [volumeClass performSelector:@selector(sharedVolumeControl)];
        if (shareInstance) {
            setVolumeLevelFun(shareInstance,@selector(setMediaVolume:),volume);
        }
        setVolumeLevelFun(shareInstance,@selector(setMediaVolume:),volume);
    }
}

#pragma mark - 获取当前音量
+(float)yk_getCurrentVolume {
    
    Class SBUIControllerCls = objc_getClass("SBUIController");
    if (!SBUIControllerCls) return -1.f;
    
    id ui =
    ((id (*)(id, SEL))objc_msgSend)(
                                    SBUIControllerCls, sel_registerName("sharedInstance"));
    if (!ui) return -1.f;
    
    Ivar ivar = class_getInstanceVariable(
                                          object_getClass(ui), "_volumeControl");
    if (!ivar) return -1.f;
    
    id vc = object_getIvar(ui, ivar);
    if (!vc) return -1.f;
    
    SEL sel = sel_registerName("_effectiveVolume");
    if (![vc respondsToSelector:sel]) return -1.f;
    
    return ((float (*)(id, SEL))objc_msgSend)(vc, sel);
}

#pragma mark - 设置小白球是否启用
+(void)yk_setAssistiveTouchEnable:(BOOL)enabled {
    [objc_getClass("PSAssistiveTouchSettingsDetail") setEnabled:enabled];
}

#pragma mark - 是否开启了小白球
+(BOOL)yk_isAssistiveTouchEnabled {
    return [objc_getClass("PSAssistiveTouchSettingsDetail") isEnabled];
}


#pragma mark - 设置减小动画
typedef int (*AXSSetReduceMotionEnabledFunc)(int);
+(void)yk_setReduceMotionEnable:(BOOL)enabled {
    
    void *handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_LAZY);
    if (!handle) return;
    
    AXSSetReduceMotionEnabledFunc setFunc =
    (AXSSetReduceMotionEnabledFunc)dlsym(handle, "_AXSSetReduceMotionEnabled");
    
    if (setFunc) {
        setFunc(enabled ? 1 : 0);
    }
    
    dlclose(handle);
}

#pragma mark - 获取当前 Reduce Motion 状态
+(BOOL)yk_isReduceMotionEnabled {
    
    BOOL enabled = NO;
    void *handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_LAZY);
    if (!handle) return NO;
    
    typedef int (*AXSReduceMotionEnabledFunc)(void);
    AXSReduceMotionEnabledFunc getFunc = (AXSReduceMotionEnabledFunc)dlsym(handle, "_AXSReduceMotionEnabled");
    
    if (getFunc) {
        enabled = getFunc() ? YES : NO;
    }
    
    dlclose(handle);
    return enabled;
}

#pragma mark - 加载Safari设置
+(void)yk_loadMobileSafariSettingsBundle
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/MobileSafariSettings.bundle"] load];
    });
}
+(id)yk_sharedSafariDeveloperSettingsController
{
    static id safariCtrl = nil;
    if (!safariCtrl) {
        [self yk_loadMobileSafariSettingsBundle];
        Class cls = objc_getClass("SafariDeveloperSettingsController");
        if (cls) {
            safariCtrl = [[cls alloc] init];
        }
    }
    return safariCtrl;
}

#pragma mark - 设置Safari网页检查器
+(void)yk_setRemoteInspectorEnable:(BOOL)enabled {
    
    [[self yk_sharedSafariDeveloperSettingsController] setRemoteInspectorEnabled:@(enabled) specifier:nil];
}

#pragma mark - 获取Safari网页检查器是否开启
+(BOOL)yk_isRemoteInspectorEnabled {
    return [[[self yk_sharedSafariDeveloperSettingsController] remoteInspectorEnabled:nil] boolValue];
}


#pragma mark - 加载DisplayAndBrightnessSettings
+(void)yk_loadDisplayAndBrightnessSettingsFramework
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework"] load];
    });
}

+(id)yk_sharedDBSSettingsController
{
    static DBSSettingsController *dbsCtrl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self yk_loadDisplayAndBrightnessSettingsFramework];
        dbsCtrl = [[objc_getClass("DBSSettingsController") alloc] init];
    });
    return dbsCtrl;
}

#pragma mark - 设置设备自动锁定（Auto-Lock）的时间间隔
+(void)yk_setAutoLockTimeInSeconds:(NSTimeInterval)seconds {
    
    if (seconds == -1 || seconds == 0) {
        [[self yk_sharedDBSSettingsController] setScreenLock:@(INT32_MAX) specifier:nil];
    } else {
        [[self yk_sharedDBSSettingsController] setScreenLock:@((NSInteger)round(seconds)) specifier:nil];
    }
}

#pragma mark - 获取当前设备自动锁定（Auto-Lock）的时间间隔
+(NSTimeInterval)yk_autoLockTimeInSeconds {
    return [[[self yk_sharedDBSSettingsController] screenLock:nil] integerValue];
}


#pragma mark - 设置Preference
+(void)yk_setPreference:(NSString *)domain yk_preferenceKey:(NSString *)key yk_preValue:(id)value {
    if (!domain || !key || !value) return;
    @try {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:value forKey:key inDomain:domain];
        [defaults synchronize];
    } @catch (NSException *exception) {
        LOGI(@"[YKSystemSettings] Set Preference Error: %@", exception);
    }
}

#pragma mark - 获取系统指定域的配置
+(NSString *)yk_getPreferencesWithDomain:(NSString *)domain {
    
    if (!domain) return @"{}";
    
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
    if (!dict || dict.count == 0) return @"{}";
    
    @try {
        // 【关键改动】：递归清洗整个字典，无论嵌套多深
        id cleanedDict = [self yk_cleanObjectForJSON:dict];
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cleanedDict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (!jsonData) {
            return @"{}";
        }
        
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        return @"{}";
    }
}



#pragma mark - 递归清洗对象，确保可以被 JSON 序列化
+(id)yk_cleanObjectForJSON:(id)object {
    // 1. 处理字典：递归清洗每一个 Value
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *cleanedDict = [NSMutableDictionary dictionaryWithCapacity:[object count]];
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            // JSON 的 Key 必须是字符串
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : [key description];
            cleanedDict[stringKey] = [self yk_cleanObjectForJSON:obj];
        }];
        return cleanedDict;
    }
    
    // 2. 处理数组：递归清洗每一个元素
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *cleanedArray = [NSMutableArray arrayWithCapacity:[object count]];
        for (id item in object) {
            [cleanedArray addObject:[self yk_cleanObjectForJSON:item]];
        }
        return cleanedArray;
    }
    
    // 3. 处理不支持的类型：Data
    if ([object isKindOfClass:[NSData class]]) {
        return [object description]; // 或者使用 [object base64EncodedStringWithOptions:0]
    }
    
    // 4. 处理不支持的类型：Date
    if ([object isKindOfClass:[NSDate class]]) {
        return [object description];
    }
    
    // 5. 处理基础合法类型：String, Number, Null
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]] ||
        [object isKindOfClass:[NSNull class]]) {
        return object;
    }
    
    // 6. 兜底处理：如 NSURL 等其他类型全部转为字符串
    return [object description];
}

#pragma mark - 设置是否忽略用户交互事件 (物理点击屏蔽)
+(void)yk_setIgnoreTouchEnable:(BOOL)enabled {
    if (enabled) {
        [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] beginIgnoringInteractionEvents];
    } else {
        [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] endIgnoringInteractionEvents];
    }
}

#pragma mark - 加载语言
+(void)yk_loadInternationalSettingsBundle
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/InternationalSettings.bundle"] load];
    });
}


#pragma mark - 获取当前语言
+(NSString *)yk_currentLanguage {
    return [[NSLocale preferredLanguages] firstObject];
}

#pragma mark - 设置语言
+(void)yk_setCurrentLanguage:(NSString *)language {
    @autoreleasepool {
        
        NSString *currentLanguage = [self yk_currentLanguage];
        // 如果当前语言和新语言完全相同，直接返回，不进行修改
        if ([currentLanguage isEqualToString:language]) {
            LOGI(@"当前语言与目标语言相同，无需更改。");
            return; // 跳过语言更改
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self yk_loadInternationalSettingsBundle];
                
                NSString *languageCode = yk_InternationalSettingsExtractLanguageCode(language);
                Class internationalSettingsController = objc_getClass("InternationalSettingsController");
                [internationalSettingsController setPreferredLanguages:@[languageCode]];
                if ([internationalSettingsController respondsToSelector:@selector(setCurrentLanguage:)])
                {
                    [internationalSettingsController setCurrentLanguage:languageCode];
                }
                else if ([internationalSettingsController respondsToSelector:@selector(setLanguage:)])
                {
                    [internationalSettingsController setLanguage:languageCode];
                }
            }
        });
    }
}


#pragma mark - airDrop
+(void)yk_loadSharingUIFramework
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SharingUI.framework"] load];
    });
}

+ (id)yk_sharedSFAirDropDiscoveryController
{
    static SFAirDropDiscoveryController *addCtrl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self yk_loadSharingUIFramework];
        addCtrl = [[objc_getClass("SFAirDropDiscoveryController") alloc] init];
    });
    return addCtrl;
}

#pragma mark - 获取AirDrop模式
+(NSInteger)yk_airDropDiscoveryMode {
    return [[self yk_sharedSFAirDropDiscoveryController] discoverableMode];
}

#pragma mark - 设置AirDrop模式
+(void)yk_setAirDropDiscoveryMode:(NSInteger)discoveryMode {
    [[self yk_sharedSFAirDropDiscoveryController] setDiscoverableMode:discoveryMode];
}


#pragma mark - 加载VPN类
+(void)yk_loadVPNPreferencesBundle
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/VPNPreferences.bundle"] load];
    });
}

#pragma mark - 设置VPN
+(void)yk_setVPNEnable:(BOOL)enabled {
    
    void (*setVpnActive)(id,SEL,BOOL) = (void(*)(id,SEL,BOOL))objc_msgSend;
    [self yk_loadVPNPreferencesBundle];
    Class VPNBundleControllerClass = objc_getClass("VPNBundleController");
    if (VPNBundleControllerClass) {
        id VPNBC = ((id (*)(id, SEL))objc_msgSend)(VPNBundleControllerClass, @selector(alloc));
        SEL initWithParentListControllerSEL = @selector(initWithParentListController:);
        if ([VPNBC respondsToSelector:initWithParentListControllerSEL]) {
            VPNBC = ((id (*)(id, SEL, id))objc_msgSend)(VPNBC, initWithParentListControllerSEL, nil);
            if ([VPNBC respondsToSelector:@selector(setVPNActive:)]) {
                setVpnActive(VPNBC, @selector(setVPNActive:), enabled);
            } else if ([VPNBC respondsToSelector:@selector(_setVPNActive:)]) {
                setVpnActive(VPNBC, @selector(_setVPNActive:), enabled);
            }
        }
    }
}

#pragma mark - 获取VPN连接状态
+(BOOL)yk_getVPNStatus {
    
    BOOL (*isUsingVPNConnection)(id,SEL) = (BOOL(*)(id,SEL))objc_msgSend;
    id (*shareManager)(id,SEL) = (id(*)(id,SEL))objc_msgSend;
    Class SBTelephonyManagercls = objc_getClass("SBTelephonyManager");
    id sharedTelephonyManager = shareManager(SBTelephonyManagercls, @selector(sharedTelephonyManager));
    BOOL flag = isUsingVPNConnection(sharedTelephonyManager, @selector(isUsingVPNConnection));
    return flag;
}

#pragma mark - 获取VPN列表
+(NSString *)yk_getVPNList {
    
    [self yk_loadVPNPreferencesBundle];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    Class VPNConnectionStore = NSClassFromString(@"VPNConnectionStore");
    id store = [VPNConnectionStore sharedInstance];
    for (NEConfiguration *config in [store configurations])
    {
        //LOGI(@"类型=%@, 输出结果%@", NSStringFromClass([config class], config);
        if ([config.name isEqualToString:@"com.apple.preferences.networkprivacy"]) {
            LOGI(@"系统的网络协议私有");
        } else {
            
            NSDictionary *dic = @{
                @"name": config.name ?: @"",
                @"identifier": config.identifier.UUIDString ?: @"",
                @"applicationName": config.applicationName ?: @"",
                @"applicationIdentifier": config.applicationIdentifier ?: @""
            };
            [result addObject:dic];
        }
    }
    
    if (result.count == 0) {
        return @"{}";
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result
                                                       options:0
                                                         error:&error];
    if (error || !jsonData) {
        return @"{}";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


#pragma mark - 添加VPN信息
+(BOOL)yk_addVPN:(NSDictionary *)info {
    
    [self yk_loadVPNPreferencesBundle];
    Class VPNConnectionStore = NSClassFromString(@"VPNConnectionStore");
    id store = [VPNConnectionStore sharedInstance];
    BOOL result = [store createVPNWithOptions:info];
    return result;
}

#pragma mark - 删除VPN
+(BOOL)yk_deleteVPN:(NSString *)identifier {
    
    [self yk_loadVPNPreferencesBundle];
    bool result = false;
    Class VPNConnectionStore = NSClassFromString(@"VPNConnectionStore");
    id store = [VPNConnectionStore sharedInstance];
    
    for (NEConfiguration *config in [store configurations])
    {
        if ([identifier isEqualToString:@"*"]) {
            //删除所有
            result = [store deleteVPNWithServiceID:config.identifier];
        } else {
            
            if ([identifier isEqualToString:config.identifier.UUIDString] || [identifier isEqualToString:config.name]) {
                result = [store deleteVPNWithServiceID:config.identifier];
            }
        }
    }
    return result;
}

#pragma mark - 选择VPN
+(BOOL)yk_selectVPN:(NSString *)identifier {
    
    Class VPNConnectionStore = NSClassFromString(@"VPNConnectionStore");
    id store = [VPNConnectionStore sharedInstance];
    for (NEConfiguration *config in [store configurations])
    {
        if ([identifier isEqualToString:config.identifier.UUIDString] || [identifier isEqualToString:config.name])
        {
            [store setActiveVPNID:config.identifier withGrade:0];
            return YES;
        }
    }
    return NO;
}


#pragma mark - 获取设备所有底层的移动通讯硬件信息
+(NSDictionary *)yk_getAbsoluteAllDeviceInfo {
    
    NSMutableDictionary *allData = [NSMutableDictionary dictionary];
    id (*idMsgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
    
    Class SBTelephonyManagercls = objc_getClass("SBTelephonyManager");
    id sharedTelephonyManager = idMsgSend(SBTelephonyManagercls, @selector(sharedTelephonyManager));
    
    id coreTelephonyClient = idMsgSend(sharedTelephonyManager, @selector(coreTelephonyClient));
    NSString *qinfo = nil;
    id (*getMobileEquipmentInfoFun)(id,SEL,NSString **) = (id(*)(id,SEL,NSString **))objc_msgSend;
    id mobileEquipmentInfoList = getMobileEquipmentInfoFun(coreTelephonyClient, @selector(getMobileEquipmentInfo:), &qinfo);
    
    if (mobileEquipmentInfoList) {
        // 5. 获取包含所有卡槽信息对象的数组 (meInfoList)
        NSArray *infoList = idMsgSend(mobileEquipmentInfoList, @selector(meInfoList));
        
        // 6. 遍历所有卡槽信息（例如双卡手机会有 Slot 0 和 Slot 1）
        for (id meInfo in infoList) {
            // 定义专门用于获取整数返回值（如 SlotId）的函数指针
            long long (*intMsgSend)(id, SEL) = (long long(*)(id, SEL))objc_msgSend;
            long long slotId = intMsgSend(meInfo, @selector(slotId)); // 获取卡槽编号
            
            // 创建一个字典存储当前卡槽的信息
            NSMutableDictionary *slotData = [NSMutableDictionary dictionary];
            
            // 7. 提取各项硬件标识符，如果为 nil 则记录为 "N/A"
            // IMEI: 手机硬件身份证
            slotData[@"IMEI"] = idMsgSend(meInfo, @selector(IMEI)) ?: @"N/A";
            // IMSI: SIM 卡用户识别码
            slotData[@"IMSI"] = idMsgSend(meInfo, @selector(IMSI)) ?: @"N/A";
            // ICCID: SIM 卡物理卡号
            slotData[@"ICCID"] = idMsgSend(meInfo, @selector(ICCID)) ?: @"N/A";
            // MEID: 移动设备识别码 (CDMA制式)
            slotData[@"MEID"] = idMsgSend(meInfo, @selector(MEID)) ?: @"N/A";
            // CSN: 卡片序列号
            slotData[@"CSN"] = idMsgSend(meInfo, @selector(CSN)) ?: @"N/A";
            
            // 以卡槽 ID 为 Key (如 Slot_0) 存入主结果字典
            NSString *slotKey = [NSString stringWithFormat:@"Slot_%lld", slotId];
            allData[slotKey] = slotData;
        }
    }
    return allData;
}


+(void)yk_dumpAllTelephonyKeys {
    // 基础消息发送函数
    id (*idMsgSend)(id, SEL) = (id(*)(id, SEL))objc_msgSend;
    
    Class SBTelephonyManagercls = objc_getClass("SBTelephonyManager");
    if (!SBTelephonyManagercls) return;
    
    id sharedTelephonyManager = idMsgSend(SBTelephonyManagercls, @selector(sharedTelephonyManager));
    if (!sharedTelephonyManager) return;
    
    id coreTelephonyClient = idMsgSend(sharedTelephonyManager, @selector(coreTelephonyClient));
    if (!coreTelephonyClient) return;
    
    NSString *qinfo = nil;
    // 注意：这里的返回值和参数需要根据实际情况匹配
    id (*getMobileEquipmentInfoFun)(id,SEL,NSString **) = (id(*)(id,SEL,NSString **))objc_msgSend;
    id mobileEquipmentInfoList = getMobileEquipmentInfoFun(coreTelephonyClient, @selector(getMobileEquipmentInfo:), &qinfo);
    
    if (mobileEquipmentInfoList) {
        NSArray *infoList = idMsgSend(mobileEquipmentInfoList, @selector(meInfoList));
        if (infoList && infoList.count > 0) {
            
            id mobileEquipmentInfo = infoList[0];
            LOGI(@"[YK] 正在分析类: %s", object_getClassName(mobileEquipmentInfo));
            
            unsigned int count;
            objc_property_t *properties = class_copyPropertyList([mobileEquipmentInfo class], &count);
            
            for (int i = 0; i < count; i++) {
                const char *propertyName = property_getName(properties[i]);
                const char *attributes = property_getAttributes(properties[i]);
                NSString *key = [NSString stringWithUTF8String:propertyName];
                NSString *attrStr = [NSString stringWithUTF8String:attributes];
                
                SEL selector = NSSelectorFromString(key);
                
                // --- 核心修复：检查类型编码 ---
                // T@"NSString" 代表对象，Tq 代表 long, Ti 代表 int, TB 代表 BOOL
                if (attrStr.length > 1 && [attrStr characterAtIndex:1] == '@') {
                    // 只有对象类型才用 id 接收，防止 ARC 调用 objc_retain 导致崩溃
                    @try {
                        id value = idMsgSend(mobileEquipmentInfo, selector);
                        LOGI(@"[YK] [对象] %@ = %@", key, value);
                    } @catch (NSException *e) { }
                }
                else if ([attrStr containsString:@"Tq"] || [attrStr containsString:@"Ti"]) {
                    // 处理整数类型 (int / long long)
                    long long (*intMsgSend)(id, SEL) = (long long(*)(id, SEL))objc_msgSend;
                    long long val = intMsgSend(mobileEquipmentInfo, selector);
                    LOGI(@"[YK] [数字] %@ = %lld", key, val);
                }
                else if ([attrStr containsString:@"TB"] || [attrStr containsString:@"Tc"]) {
                    // 处理布尔类型
                    BOOL (*boolMsgSend)(id, SEL) = (BOOL(*)(id, SEL))objc_msgSend;
                    BOOL val = boolMsgSend(mobileEquipmentInfo, selector);
                    LOGI(@"[YK] [布尔] %@ = %@", key, val ? @"YES" : @"NO");
                }
                else {
                    LOGI(@"[YK] [其他] %@ 类型为: %@", key, attrStr);
                }
            }
            free(properties);
        }
    }
}
@end
#pragma clang diagnostic pop

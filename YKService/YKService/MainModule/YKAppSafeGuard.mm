////
////  YKAppSafeGuard.m
////  Created on 2025/12/26
////  Description: App 安全防护 (反调试/反注入)
////  Copyright © 2025 YKKJ. All rights reserved.
////
//
//// 必须按顺序添加这三个头文件来完整定义 kinfo_proc
//#import <sys/types.h>
//#import <sys/param.h>
//#import <sys/sysctl.h>
//
//// 核心系统库
//#import <sys/syscall.h> // 用于 syscall
//#import <unistd.h>      // 用于 getpid() 和 close()
//
//// 用于反 Frida/反注入检测
//#import <mach-o/dyld.h>  // 动态库检测
//#import <mach/mach.h>    // 线程检测
//#import <pthread.h>      // 线程操作
//#import <netinet/in.h>   // 端口检测
//#import <arpa/inet.h>    // 端口检测
//#import <objc/runtime.h> // 类名检测
//
//#import "YKCrashLogs.h"
//#import "YKAppSafeGuard.h"
//#import "YKServiceLogger.h"
//
//// 如果编译依然报错，说明该版本的 iOS SDK 隐藏了 kinfo_proc
//#ifndef P_TRACED
//#define P_TRACED 0x00000800
//#endif
//
//
//#define yk_crashApp                         A8872d12xa99b7bef1a38319460e0ea84e5
//#define yk_startAntiDebugLogic              B251242x11544bd528c0e7b77d6e3ff75fb
//#define yk_checkDebuggerStatus              C959f822dcbe219abb94ce0f454876a002c
//#define yk_isDebuggerAttachedBySysctl       D7ac3aee82sfcbdd0b9b7ea7ca6759e54e4
//#define yk_isFridaDetected                  E0660521fe60ecb3d3ad0abf4603af2cc28
//#define yk_checkFridaThreads                Fd3acdb12bff6c68a1c9dbf21ba83f92e72
//#define yk_checkInjectedLibraries           G8c771451cae8073cc212373fcb27d66683
//#define yk_checkFridaPort                   Hf6f81d6cae23bd9128966ded1edbed48b6
//#define yk_checkFridaClasses                I4af555be11a21a2lba75b33d87af183a90
//
//#if YKLogMode == 0
//@implementation YKAppSafeGuard
//
///**
// * 统一的崩溃方法，强制退出
// */
//+(void)yk_crashApp {
//    // 方式：汇编指令崩溃 (SIGTRAP/SIGILL)，难以被 try-catch 或 Hook exit 拦截
//#if defined(__arm64__)
//    asm("brk 1");
//#else
//    exit(1);
//#endif
//}
//
///**
// * +load 方法会在类被加载到内存时调用
// */
//+(void)load {
//    
//    // 1. 启动时立即检测
//    [self yk_startAntiDebugLogic];
//
//    // 2. 开启 GCD Timer 循环检测 (比 NSTimer 更底层，不依赖 RunLoop 模式)
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//    static dispatch_source_t antiDebugTimer;
//    antiDebugTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
//    
//    // 每 5 秒检测一次
//    dispatch_source_set_timer(antiDebugTimer, DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
//    
//    dispatch_source_set_event_handler(antiDebugTimer, ^{
//        [self.class yk_checkDebuggerStatus];
//    });
//    
//    dispatch_resume(antiDebugTimer);
//    LOGI(@"远控定时反调试检测已启动.");
//}
//
//+ (void)yk_startAntiDebugLogic {
//    // 方法 A: 利用 svc 中断调用 ptrace (PT_DENY_ATTACH)
//    // 效果：如果启动时就有调试器附加，App 会直接闪退
//#if defined(__arm64__)
//    asm volatile(
//         "mov x0, #31\n"    // PT_DENY_ATTACH
//         "mov x1, #0\n"     // pid
//         "mov x2, #0\n"     // addr
//         "mov x3, #0\n"     // data
//         "mov x16, #26\n"   // syscall 26 (ptrace)
//         "svc #0x80\n"
//    );
//#endif
//
//    // 方法 B: 执行一次状态检查
//    [self yk_checkDebuggerStatus];
//}
//
//+(void)yk_checkDebuggerStatus {
//    
//    // 1. Sysctl 检测 (基础 P_TRACED)
//    if ([self yk_isDebuggerAttachedBySysctl]) {
//        LOGI(@"检测到调试器通过 Sysctl (P_TRACED).");
//        YKCrashLogs::getInstance().writeManualLog(@"S");
//        [NSThread sleepForTimeInterval:2.0];
//        [self yk_crashApp];
//    }
//
//    // 2. Frida/注入 综合特征检测 (核心优化部分)
//    if ([self yk_isFridaDetected]) {
//        LOGI(@"检测到 Frida 或 恶意注入痕迹，执行强制退出.");
//        YKCrashLogs::getInstance().writeManualLog(@"F");
//        [NSThread sleepForTimeInterval:2.0];
//        [self yk_crashApp];
//    }
//}
//
//#pragma mark - 反调试检测实现
//
//#pragma mark - 1. Sysctl 检测
//+ (BOOL)yk_isDebuggerAttachedBySysctl {
//    
//    int name[4];
//    struct kinfo_proc info;
//    size_t info_size = sizeof(info);
//
//    info.kp_proc.p_flag = 0;
//
//    name[0] = CTL_KERN;
//    name[1] = KERN_PROC;
//    name[2] = KERN_PROC_PID;
//    name[3] = getpid();
//
//    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
//        return NO;
//    }
//
//    return ((info.kp_proc.p_flag & P_TRACED) != 0);
//}
//
//#pragma mark - 2. Frida 综合检测 (重点完善)
//
//+ (BOOL)yk_isFridaDetected {
//    // 按优先级顺序检测，只要命中一个即返回 YES
//    
//    // A. 线程特征检测 (最准确，针对 GumJS 引擎)
//    if ([self yk_checkFridaThreads]) return YES;
//    
//    // B. 动态库加载检测 (针对 frida-agent.dylib)
//    if ([self yk_checkInjectedLibraries]) return YES;
//    
//    // C. 端口检测 (针对 frida-server 默认端口 27042)
//    if ([self yk_checkFridaPort]) return YES;
//    
//    // D. 运行库类名检测 (针对 FridaGadget)
//    if ([self yk_checkFridaClasses]) return YES;
//    
//    return NO;
//}
//
//// ----------------------------------------------------------------------
//// 2.A 检测 Frida 特有的后台线程 (gum-js-loop)
//// ----------------------------------------------------------------------
//+(BOOL)yk_checkFridaThreads {
//    
//    thread_act_array_t threads;
//    mach_msg_type_number_t thread_count = 0;
//    
//    kern_return_t kr = task_threads(mach_task_self(), &threads, &thread_count);
//    if (kr != KERN_SUCCESS) return NO;
//    
//    BOOL detected = NO;
//    
//    for (int i = 0; i < thread_count; i++) {
//        char name[256];
//        name[0] = '\0';
//        
//        pthread_t pt = pthread_from_mach_thread_np(threads[i]);
//        if (pt) {
//            pthread_getname_np(pt, name, sizeof(name));
//            // 转换为小写比较，或者直接 strstr
//            if (strstr(name, "gum-js-loop") || strstr(name, "gmain")) {
//                LOGI(@"检测到 Frida 线程特征: %s", name);
//                detected = YES;
//                break;
//            }
//        }
//    }
//    
//    // 释放 Mach 端口资源
//    vm_deallocate(mach_task_self(), (vm_address_t)threads, sizeof(thread_t) * thread_count);
//    return detected;
//}
//
//// ----------------------------------------------------------------------
//// 2.B 检测加载的镜像 (Images)
//// ----------------------------------------------------------------------
//+ (BOOL)yk_checkInjectedLibraries {
//    uint32_t count = _dyld_image_count();
//    for (uint32_t i = 0; i < count; i++) {
//        const char *imageName = _dyld_get_image_name(i);
//        if (!imageName) continue;
//        
//        // 使用 C 函数 strstr 避免 ObjC Runtime 干扰
//        // 检测关键词：FridaGadget, frida-agent, cynject (Cycript)
//        if (strstr(imageName, "FridaGadget") ||
//            strstr(imageName, "frida-agent") ||
//            strstr(imageName, "cynject") ||
//            strstr(imageName, "SSLKillSwitch")) { // 常见的抓包插件
//            
//            LOGI(@"检测到非法注入库: %s", imageName);
//            return YES;
//        }
//    }
//    return NO;
//}
//
//// ----------------------------------------------------------------------
//// 2.C 检测 Frida 默认端口 27042
//// ----------------------------------------------------------------------
//+ (BOOL)yk_checkFridaPort {
//    
//    struct sockaddr_in server_addr;
//    memset(&server_addr, 0, sizeof(server_addr));
//    server_addr.sin_family = AF_INET;
//    server_addr.sin_port = htons(27042);
//    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
//    
//    int sock = socket(AF_INET, SOCK_STREAM, 0);
//    if (sock < 0) return NO;
//    
//    // 设置非阻塞
//    int flags = fcntl(sock, F_GETFL, 0);
//    fcntl(sock, F_SETFL, flags | O_NONBLOCK);
//    
//    int result = connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
//    BOOL isOpen = NO;
//    
//    if (result == 0) {
//        // 极少见，瞬间连接成功
//        isOpen = YES;
//    } else if (errno == EINPROGRESS) {
//        // 连接正在进行中，需要使用 select 等待结果
//        fd_set writeset;
//        FD_ZERO(&writeset);
//        FD_SET(sock, &writeset);
//        
//        // 设置超时时间 (例如 100毫秒)
//        // 本地连接通常只需几毫秒，给多点防止误判
//        struct timeval tv;
//        tv.tv_sec = 0;
//        tv.tv_usec = 100000;
//        
//        // 等待 Socket 变为可写
//        if (select(sock + 1, NULL, &writeset, NULL, &tv) > 0) {
//            // select 返回 > 0 表示 socket 状态有变化（可写或出错）
//            int so_error;
//            socklen_t len = sizeof(so_error);
//            
//            // 获取 Socket 的错误状态
//            getsockopt(sock, SOL_SOCKET, SO_ERROR, &so_error, &len);
//            
//            if (so_error == 0) {
//                // 没有错误，说明连接成功！端口是开放的
//                isOpen = YES;
//            } else {
//                // so_error 通常是 ECONNREFUSED (61)，表示端口关闭
//                // LOGI(@"连接失败，错误码: %d", so_error);
//            }
//        }
//    }
//    
//    close(sock);
//    
//    if (isOpen) {
//        LOGI(@"检测到本地端口 27042 开放 (Frida Server).");
//    }
//    return isOpen;
//}
//
//// ----------------------------------------------------------------------
//// 2.D 检测 Objective-C 类名
//// ----------------------------------------------------------------------
//+ (BOOL)yk_checkFridaClasses {
//    // 某些版本的 Frida Gadget 可能会注册此类
//    if (objc_getClass("FridaGadget")) {
//        LOGI(@"检测到 FridaGadget 类存在.");
//        return YES;
//    }
//    return NO;
//}
//
//@end
//
//#endif

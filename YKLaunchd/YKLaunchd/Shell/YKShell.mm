//
//  YKShell.m
//  YKLaunchd
//
//  Created by liuxiaobin on 2025/9/14.
//

#import <spawn.h>
#import <unistd.h>
#import "YKShell.h"
#import "YKLaunchdLogger.h"


//============================================================
// 路径节点
//============================================================
#if defined(ROOTLESS)
#define JBROOT(X)   "/var/jb" X
#elif defined(ROOTHIDE)
#import "roothide.h"
#define JBROOT(X)   jbroot(X)
#else
#define JBROOT(X)   X
#endif


#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
// 声明外部 C 函数（这些是系统私有API，用于设置进程身份）
extern "C" {
    int posix_spawnattr_set_persona_np(const posix_spawnattr_t*, uid_t, uint32_t);
    int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t*, uid_t);
    int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t*, uid_t);
}

typedef NS_OPTIONS(NSUInteger, SpawnFlag) {
    SpawnFlagRoot     = 1 << 0,  // 0x01
    SpawnFlagNoWait   = 1 << 1,  // 0x02
};


#pragma mark - 从管道读取UTF-8格式数据并转换为字符串
static void readPipeToString(int fd, NSMutableString* ms) {
    if (fcntl(fd, F_GETFD) == -1 && errno == EBADF) return;
    
    char buffer[4096];
    ssize_t num_read;
    
    while ((num_read = read(fd, buffer, sizeof(buffer))) > 0) {
        // 严格UTF-8解码（带错误检测）
        NSString *chunk = [[NSString alloc] initWithBytesNoCopy:buffer
                                                         length:num_read
                                                       encoding:NSUTF8StringEncoding
                                                   freeWhenDone:NO];
        
        if (!chunk) {
            // 如果不是合法UTF-8，尝试清理无效字节（防御性编程）
            NSData *data = [NSData dataWithBytes:buffer length:num_read];
            chunk = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
            
            if (!chunk) {
                // 终极fallback：替换无效UTF-8序列
                chunk = [[NSString alloc] initWithCString:buffer
                                                 encoding:NSUTF8StringEncoding];
                if (!chunk) {
                    chunk = @"[INVALID_UTF8_DATA]";
                }
            }
        }
        
        if (chunk) {
            [ms appendString:chunk];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation YKShell


#pragma mark - 简单的Shell 命令不带任何返回值
+(void)simple:(NSString *)cmd {
    
    [self simple:cmd completion:^(BOOL result, NSString * msg)
     {
        if (result)
        {
            LOGI(@"✅ 操作命令%@成功", cmd);
        } else {
            LOGI(@"❌ 操作命令%@,失败%@", cmd, msg);
        }
    }];
}


#pragma mark - 简单的Shell 命令 带有callback返回值
+(void)simple:(NSString *)cmd completion:(void (^)(BOOL, NSString * _Nullable))completion {
    
    int status = -1;
    
    // 1. 设置环境变量
    NSArray *environment = @[
        [NSString stringWithFormat:@"PATH=%s:%s:%s:%s",
         JBROOT("/usr/bin"),
         JBROOT("/usr/local/bin"),
         JBROOT("/bin"),
         JBROOT("/usr/sbin")]
    ];
    
    
    // 2. 转换环境变量为C数组
    char *env[environment.count + 1];
    for (int i = 0; i < environment.count; i++) {
        NSString *envStr = environment[i];
        env[i] = strdup(envStr.UTF8String);
    }
    env[environment.count] = NULL;
    
    
    // 3. 准备参数数组
    pid_t pid;
    const char *argv[] = {
        "sh",       // argv[0] = shell路径
        "-c",       // argv[1] = 执行命令的选项
        (char *)cmd.UTF8String, // argv[2] = 要执行的命令
        NULL        // 终止符
    };
    
    
    // 4. 执行posix_spawn
    status = posix_spawn(&pid, JBROOT("/bin/sh"), NULL, NULL, (char *const *)argv, env);
    
    // 5. 释放环境变量内存
    for (int i = 0; i < environment.count; i++) {
        free(env[i]);
    }
    
    // 6. 处理结果
    if (status == 0) {
        waitpid(pid, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            completion(YES, @"执行成功");
        } else {
            completion(NO, [NSString stringWithFormat:@"命令执行失败，错误码: %d", WEXITSTATUS(status)]);
        }
    } else {
        completion(NO, [NSString stringWithFormat:@"命令执行失败: %s", strerror(status)]);
    }
}

#pragma mark - 执行一个命令并可选捕获其标准输出
+(int)spawnWithArgs:(NSArray<NSString *> *)args stdOut:(NSString * _Nonnull __autoreleasing *)stdOut flag:(int)flag {
    
    NSArray <NSString *> *environment = @[
        @"/bin",
        @"/sbin",
        @"/usr/bin",
        @"/usr/sbin",
        @"/usr/local/bin",
        @"/usr/local/sbin",
        @(JBROOT("/bin")),
        @(JBROOT("/sbin")),
        @(JBROOT("/usr/bin")),
        @(JBROOT("/usr/sbin")),
        @(JBROOT("/usr/local/bin")),
        @(JBROOT("/usr/local/sbin")),
    ];
    char *env[environment.count + 1];
    for (int i = 0; i < environment.count; i++) {
        NSString *envStr = environment[i];
        env[i] = strdup(envStr.UTF8String);
    }
    env[environment.count] = NULL;
    
    
    NSString* file = args.firstObject;
    NSUInteger argCount = [args count];
    
    // 准备 C 风格的参数数组
    const char** argsC = (const char**)malloc((argCount + 1) * sizeof(char*));
    for (NSUInteger i = 0; i < argCount; i++) {
        argsC[i] = [args[i] UTF8String];
    }
    argsC[argCount] = NULL;  // 参数数组必须以 NULL 结尾
    
    // 初始化 spawn 属性
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    
    // 如果设置了 ROOT 标志，设置进程身份为 root
    if ((flag & SpawnFlagRoot) != 0) {
        posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
        posix_spawnattr_set_persona_uid_np(&attr, 0);  // UID 0 = root
        posix_spawnattr_set_persona_gid_np(&attr, 0);  // GID 0 = root
    }
    
    // 初始化文件操作
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    
    // 检查是否需要捕获输出
    BOOL outEnabled = stdOut != nil;
    int outOut[2], outErr[2];  // 管道文件描述符
    
    if (outEnabled) {
        // 创建管道用于标准输出
        pipe(outOut);
        posix_spawn_file_actions_adddup2(&action, outOut[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, outOut[0]);
        
        // 创建管道用于标准错误
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }
    
    // 执行 spawn
    pid_t task_pid = -1;
    int err_spawn = posix_spawn(&task_pid, file.UTF8String, &action, &attr, (char* const*)argsC, env);
    
    // 清理资源
    posix_spawnattr_destroy(&attr);
    for (int i = 0; i < environment.count; i++) {
        free(env[i]);
    }
    free(argsC);
    
    // 处理 spawn 错误
    if (err_spawn != 0) {
        LOGI(@"failed with errno: %d (%s)", errno, strerror(errno));
        return -0x100 - err_spawn;  // 返回自定义错误码
    }
    
    // 如果设置了 NOWAIT 标志，立即返回
    if ((flag & SpawnFlagNoWait) != 0) {
        return 0;
    }
    
    // 准备接收输出
    NSMutableString* outString = [NSMutableString new];
    NSMutableString* errString = [NSMutableString new];
    __block volatile BOOL _isRunning = YES;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    if (outEnabled) {
        // 创建异步队列读取输出
        dispatch_queue_t logQueue = dispatch_queue_create("com.ddy.ysjlaunchd", nil);
        int outOutPipe = outOut[0];
        int outErrPipe = outErr[0];
        
        dispatch_async(logQueue, ^{
            while (_isRunning) {
                @autoreleasepool {
                    readPipeToString(outOutPipe, outString);  // 读取标准输出
                    readPipeToString(outErrPipe, errString);  // 读取标准错误
                }
            }
            dispatch_semaphore_signal(sema);  // 信号量通知读取完成
        });
    }
    
    // 等待进程结束
    int status = 0;
    do {
        if (waitpid(task_pid, &status, 0) == -1) {
            _isRunning = NO;
            if (outEnabled) {
                close(outOut[1]);
                close(outErr[1]);
            }
            return -0x200 - errno;  // 返回等待错误
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));  // 检查进程是否真正退出
    
    _isRunning = NO;
    
    // 处理输出结果
    if (outEnabled) {
        close(outOut[1]);
        close(outErr[1]);
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);  // 等待输出读取完成
        *stdOut = [NSString stringWithFormat:@"%@\n%@\n", outString, errString];  // 合并输出和错误
    }
    // 返回进程退出状态
    return WEXITSTATUS(status);
}


#pragma mark - 获取根路径
+(NSString *)getRootFSPath:(NSString *)path {
    
    NSString *newPath = path;
#ifdef ROOTHIDE
    newPath = @(rootfs(path.UTF8String));
#else
    newPath = path;
#endif
    return newPath;
}

#pragma mark - 转换路径
+(NSString *)conversionJBRoot:(NSString *)path {
    
#if ROOTLESS
    return [NSString stringWithFormat:@"/var/jb%@",path];
#elif ROOTHIDE
    return  @(jbroot(path.UTF8String));
#else
    return path;
#endif
}

#pragma mark - 是否是隐根
+(BOOL)isRootHide {
#ifdef ROOTHIDE
    return YES;
#else
    return NO;
#endif
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

@end


#pragma clang diagnostic pop

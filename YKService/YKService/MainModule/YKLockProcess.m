//
//  YKLockProcess.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/15.
//

#import "YKLockProcess.h"
#import "YKServiceLogger.h"

#define LOCKMODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
#define YKLockFilePath "/var/mobile/Library/YKApp/LockFile/YKServceLockFile"

@implementation YKLockProcess

#pragma mark - 锁进程
+(void)lockProcess {
    
    int fd;
    char buf[16];
    
    NSDictionary *strAttrib = @{
        NSFileGroupOwnerAccountName: @"mobile",
        NSFileOwnerAccountName: @"mobile"
    };
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *lockFilePath = @(YKLockFilePath);
    
    // 设置文件属性（mobile 权限）
    [fm setAttributes:strAttrib ofItemAtPath:lockFilePath error:nil];
    

    // 打开或创建锁文件
    fd = open(YKLockFilePath, O_RDWR | O_CREAT, LOCKMODE);
    if (fd < 0) {
        LOGI(@"无法打开锁文件: %@（错误: %s）", lockFilePath, strerror(errno));
        exit(EXIT_SUCCESS);
    }
    // 再次确保文件属性（防止竞争条件）
    [fm setAttributes:strAttrib ofItemAtPath:lockFilePath error:nil];
    
    // 设置文件锁
    struct flock fl = {
        .l_type = F_WRLCK,
        .l_start = 0,
        .l_whence = SEEK_SET,
        .l_len = 0
    };
    
    if (fcntl(fd, F_SETLK, &fl) == -1) {
        if (errno == EACCES || errno == EAGAIN) {
            LOGI(@" 文件已被锁定（其他进程正在运行）: %@", lockFilePath);
            close(fd);
            exit(EXIT_SUCCESS);
        } else {
            LOGI(@" 加锁失败: %@（错误: %s）", lockFilePath, strerror(errno));
            close(fd);
            exit(EXIT_FAILURE);
        }
    }
    
    // 写入当前进程 PID
    ftruncate(fd, 0);
    snprintf(buf, sizeof(buf), "%ld", (long)getpid());
    write(fd, buf, strlen(buf) + 1);
    
    LOGI(@"进程已锁定 (PID: %ld, 锁文件: %@)", (long)getpid(), lockFilePath);
}

@end

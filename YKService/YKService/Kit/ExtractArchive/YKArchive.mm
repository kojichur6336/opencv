//
//  YKArchive.m
//  YKService
//
//  Created by liuxiaobin on 2025/9/29.
//


#import "YKArchive.h"
#import <YKRarKit/UnrarKit.h>
#import <YKZipKit/SSZipArchive.h>

@implementation YKArchive

#pragma mark - 单例
+(instancetype)sharedInstance {
    static YKArchive *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 解压文件
-(void)extractArchiveAtPath:(NSString *)filePath completion:(nonnull void (^)(BOOL, NSString * msg, NSString * filePath))completion
{
    // 获取文件的扩展名
    NSString *fileExtension = [filePath pathExtension].lowercaseString;

    
    // 获取目标目录，去掉扩展名
    NSString *destinationPath = [[filePath stringByDeletingPathExtension] stringByAppendingPathComponent:[filePath lastPathComponent]];
    destinationPath = [destinationPath stringByDeletingLastPathComponent]; // 去掉文件名，保留文件夹
    
    if ([fileExtension isEqualToString:@"zip"]) {
        // 如果是 zip 文件，调用解压 zip 方法
        [self extractZipAtPath:filePath toPath:destinationPath completion:^(BOOL result, NSString * msg) {
            completion(result, msg, destinationPath);
        }];
    } else if ([fileExtension isEqualToString:@"rar"]) {
        // 如果是 rar 文件，调用解压 rar 方法
        [self extractRarFileAtPath:filePath toPath:destinationPath completion:^(BOOL result, NSString *msg) {
            completion(result, msg, destinationPath);
        }];
    } else {
        // 不支持的文件格式
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(NO, @"不支持的文件格式", @"");
        });
    }
}

#pragma mark - 压缩文件或文件夹
-(void)compressArchiveAtPath:(NSString *)archivePath
                  completion:(void (^)(BOOL success, NSString *msg, NSString *zipPath))completion {
    
    if (!archivePath.length) {
        if (completion) completion(NO, @"路径为空", @"");
        return;
    }
    
    NSString *directory = [archivePath stringByDeletingLastPathComponent];
    NSString *fileName = [[archivePath lastPathComponent] stringByDeletingPathExtension];
    NSString *zipPath = [directory stringByAppendingPathComponent:[fileName stringByAppendingString:@".zip"]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL isDir = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:archivePath isDirectory:&isDir];
        if (!exists) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, @"源文件不存在", @"");
            });
            return;
        }
        
        // 判断是否可读（有权限）
        if (![[NSFileManager defaultManager] isReadableFileAtPath:archivePath]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, @"没有访问权限", @"");
            });
            return;
        }
        
        // 如果是文件夹，还可以进一步检查是否能读取内容
        if (isDir) {
            NSError *error = nil;
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:archivePath error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(NO, @"无法读取文件夹内容，可能没有权限", @"");
                });
                return;
            }
        }
        
        BOOL success = NO;
        
        if (isDir) {
            // 压缩整个文件夹
            success = [SSZipArchive createZipFileAtPath:zipPath
                                withContentsOfDirectory:archivePath
                                    keepParentDirectory:YES];
        } else {
            // 压缩单个文件
            success = [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:@[archivePath]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                if (success) {
                    completion(YES, @"压缩成功", zipPath);
                } else {
                    completion(NO, @"压缩失败", @"");
                }
            }
        });
    });
}



#pragma mark - 解压 zip 文件
-(void)extractZipAtPath:(NSString *)zipFilePath toPath:(NSString *)destinationPath completion:(void (^)(BOOL, NSString * _Nonnull))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL success = [SSZipArchive unzipFileAtPath:zipFilePath
                                       toDestination:destinationPath
                                           overwrite:YES
                                            password:nil
                                               error:nil];
        NSString *msg = @"解压成功";
        if (success) {
            // 递归设置目标目录及其所有文件的权限
            [self setPermissionsForDirectoryAtPath:destinationPath];
        } else {
            msg = @"解压失败";
        }
        
        
        // 返回结果到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, msg);
        });
    });
}


#pragma mark - 解压Rar 文件
-(void)extractRarFileAtPath:(NSString *)rarFilePath toPath:(NSString *)destinationPath completion:(void (^)(BOOL success, NSString *msg))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        URKArchive *archive = [[URKArchive alloc] initWithPath:rarFilePath error:&error];
        if (error) {
            
            completion(NO, error.localizedDescription);
            return;
        }
        BOOL success = [archive extractFilesTo:destinationPath overwrite:YES error:&error];
        NSString *msg = @"解压成功";
        
        if (success) {
            // 递归设置目标目录及其所有文件的权限
            [self setPermissionsForDirectoryAtPath:destinationPath];
        } else {
            msg = @"解压失败";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, msg);
        });
    });
}


#pragma mark - 设置目录及其下所有文件的权限
-(void)setPermissionsForDirectoryAtPath:(NSString *)directoryPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    
    for (NSString *item in contents) {
        NSString *itemPath = [directoryPath stringByAppendingPathComponent:item];
        BOOL isDirectory = NO;
        
        // 判断是否为目录
        [fileManager fileExistsAtPath:itemPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            // 如果是目录，递归设置该目录下的文件权限
            [self setPermissionsForDirectoryAtPath:itemPath];
        } else {
            // 设置文件权限为普通权限（rw-r--r--）
            NSDictionary *attributes = @{NSFilePosixPermissions: @(0644)};
            [fileManager setAttributes:attributes ofItemAtPath:itemPath error:nil];
        }
    }
}

@end

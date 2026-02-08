//
//  YKServiceFileManager.m
//  YKService
//
//  Created by liuxiaobin on 2025/11/5.
//

#import <fts.h>
#import <sys/stat.h>
#import "YKServiceLogger.h"
#import "YKServiceFileManager.h"

@implementation YKServiceFileManager

#pragma mark - 获取文件信息
+(NSDictionary *)getFileInfo:(NSString *)path
{
    @try {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            return @{};
        }
        
        NSError *error = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
        
        NSDate *modificationDate = attributes[NSFileModificationDate];
        NSNumber *fileSize = attributes[NSFileSize];
        
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *dateStr = modificationDate ? [fmt stringFromDate:modificationDate] : @"(no date)";
        return @{@"path": path, @"size": fileSize, @"date": dateStr};
    } @catch (NSException *exception) {
        return @{};
    }
}

#pragma mark - 文件列表信息
+ (NSArray<NSDictionary *> *)findFileListInfo:(NSString *)path {
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    NSArray<NSString *> *items = [fm contentsOfDirectoryAtPath:path error:&err];
    if (err || !items) {
        LOGI(@"文件列表为空: %@", err.localizedDescription);
        return result;
    }
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    for (NSString *name in items)
    {
        @autoreleasepool
        {
            NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
            NSString *fullPath = [path stringByAppendingPathComponent:name];
            item[@"name"] = name;
            
            NSError *attrErr = nil;
            NSDictionary *attr = [fm attributesOfItemAtPath:fullPath error:&attrErr];
            if (!attr) {
                // 出错就跳过，避免 crash
                LOGI(@"跳过 %@: %@", fullPath, attrErr.localizedDescription);
                continue;
            }
            // 文件类型
            NSString *fileType = attr[NSFileType];
            item[@"type"] = fileType;
            
            // 文件权限
            NSNumber *permissions = attr[NSFilePosixPermissions];
            item[@"permissions"] = permissions;
            
            // 修改时间
            NSDate *mod = attr[NSFileModificationDate];
            NSString *dateStr = mod ? [fmt stringFromDate:mod] : @"(no date)";
            item[@"date"] = dateStr;
            
            unsigned long long size = 0;
            
            if ([fileType isEqualToString:NSFileTypeRegular]) {
                // 普通文件 → 文件大小
                size = folderContentSize(fullPath.UTF8String);
            } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
                // 目录 → 只取目录本身大小，不遍历内容（效率高）
                size = [attr fileSize];
            } else if ([fileType isEqualToString:NSFileTypeSymbolicLink]) {
                // 符号链接 → 拿到目标信息
                NSString *finalTarget = [self resolveSymlink:fullPath maxDepth:16];
                if (finalTarget == nil) {
                    finalTarget = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:fullPath error:nil];
                }
                item[@"symbolicLink"] = finalTarget;
                
                if (finalTarget)
                {
                    NSDictionary *targetAttr = [fm attributesOfItemAtPath:finalTarget error:nil];
                    if (targetAttr)
                    {
                        item[@"type"] = targetAttr[NSFileType];
                        // 文件权限
                        NSNumber *permissions = targetAttr[NSFilePosixPermissions];
                        item[@"permissions"] = permissions;
                        
                        if ([targetAttr[NSFileType] isEqualToString:NSFileTypeRegular]) {
                            // 普通文件 → 文件大小
                            size = folderContentSize(finalTarget.UTF8String);
                        } else if ([targetAttr[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                            size = [attr fileSize];
                        }
                    }
                }
            }
            
            item[@"size"] = @(size);
            [result addObject:item];
        }
    }
    return result;
}

#pragma mark - 解析符号链接，避免死循环
+(NSString *)resolveSymlink:(NSString *)path maxDepth:(NSUInteger)maxDepth {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *current = path;
    NSMutableSet *visited = [NSMutableSet set];
    
    for (NSUInteger i = 0; i < maxDepth; i++)
    {
        if ([visited containsObject:current]) {
            // 检测到循环
            return nil;
        }
        [visited addObject:current];
        
        NSError *err = nil;
        NSDictionary *attr = [fm attributesOfItemAtPath:current error:&err];
        if (!attr) break;
        
        NSString *type = attr[NSFileType];
        if (![type isEqualToString:NSFileTypeSymbolicLink]) {
            // 已经不是 link，解析结束
            return current;
        }
        
        NSString *target = [fm destinationOfSymbolicLinkAtPath:current error:nil];
        if (!target) return nil;
        
        
        // 如果是相对路径，需要拼接父目录
        if (![target hasPrefix:@"/"]) {
            target = [[[current stringByDeletingLastPathComponent] stringByAppendingPathComponent:target] stringByStandardizingPath];
        }
        current = target;
    }
    
    return nil; // 超过深度还没解析出结果
}



#pragma mark - 计算文件大小
unsigned long long folderContentSize(const char *folderPath) {
    unsigned long long total = 0;
    char * const paths[] = { (char *)folderPath, NULL };
    FTS *tree = fts_open(paths, FTS_NOCHDIR | FTS_PHYSICAL, NULL);
    if (!tree) return 0;
    
    FTSENT *node;
    while ((node = fts_read(tree)) != NULL) {
        if (node->fts_info == FTS_F) {
            total += node->fts_statp->st_size;
        }
    }
    fts_close(tree);
    return total;
}


#pragma mark - 新建文件夹
+(void)createDirectoryAtPath:(NSString *)path completion:(void (^)(BOOL, NSString *))completion {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 检查目标是否已存在
    if ([fm fileExistsAtPath:path]) {
        completion(NO, @"目标已存在，无法创建");
        return;
    }
    
    // 2. 父目录路径
    NSString *parentDir = [path stringByDeletingLastPathComponent];
    
    // 3. 检查父目录是否存在
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:parentDir isDirectory:&isDir] || !isDir) {
        completion(NO, @"父目录不存在，无法创建文件夹");
        return;
    }
    
    // 4. 检查父目录是否可写
    if (![fm isWritableFileAtPath:parentDir]) {
        completion(NO, @"没有权限在父目录下创建文件夹");
        return;
    }
    
    // 5. 尝试创建
    NSError *error;
    BOOL success = [fm createDirectoryAtPath:path
                 withIntermediateDirectories:NO
                                  attributes:nil
                                       error:&error];
    
    if (success) {
        completion(YES, @"成功");
    } else {
        completion(NO, error.localizedDescription);
    }
}

#pragma mark - 重命名文件/文件夹
+(void)renameItemAtPath:(NSString *)oldPath toName:(NSString *)newName completion:(void (^)(BOOL, NSString *))completion
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    
    // 1. 检查旧路径是否存在
    if (![fm fileExistsAtPath:oldPath]) {
        completion(NO, @"源路径不存在");
        return;
    }
    
    // 2. 目标路径 = 父目录 + 新名字
    NSString *parentDir = [oldPath stringByDeletingLastPathComponent];
    NSString *newPath = [parentDir stringByAppendingPathComponent:newName];
    
    // 3. 检查父目录是否可写
    if (![fm isWritableFileAtPath:parentDir])
    {
        completion(NO, @"没有权限修改父目录");
        return;
    }
    
    // 4. 检查目标路径是否已存在，避免覆盖
    if ([fm fileExistsAtPath:newPath])
    {
        completion(NO, @"目标已存在，不能重命名");
        return;
    }
    
    // 5. 执行重命名 (本质是 move)
    NSError *error = nil;
    if ([fm moveItemAtPath:oldPath toPath:newPath error:&error]) {
        completion(YES, @"成功");
    } else {
        completion(NO, error.localizedDescription);
    }
}

#pragma mark - 删除文件/文件夹
+(void)deleteItemAtPath:(NSString *)itemPath completion:(void (^)(BOOL, NSString *))completion
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 1. 检查是否存在
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:itemPath isDirectory:&isDir]) {
        completion(NO, @"文件或文件夹不存在");
        return;
    }
    
    // 2. 父目录路径
    NSString *parentDir = [itemPath stringByDeletingLastPathComponent];
    
    // 3. 检查父目录是否可写（删除操作其实是修改父目录目录项）
    if (![fm isWritableFileAtPath:parentDir]) {
        completion(NO, @"没有权限删除该路径下的文件/文件夹");
        return;
    }
    
    // 4. 如果是文件，还可以单独判断自身是否可写
    if (!isDir && ![fm isWritableFileAtPath:itemPath]) {
        completion(NO, @"没有权限删除该文件");
        return;
    }
    
    // 5. 尝试删除
    NSError *error = nil;
    BOOL success = [fm removeItemAtPath:itemPath error:&error];
    
    if (success) {
        completion(YES, @"成功");
    } else {
        completion(NO, error.localizedDescription);
    }
}
@end

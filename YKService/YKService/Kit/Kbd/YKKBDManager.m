//
//  YKKBDManager.m
//  YKService
//
//  Created by liuxiaobin on 2026/1/23.
//

#import <spawn.h>
#import <sqlite3.h>
#import <unistd.h>
#import <sys/stat.h>
#import "YKKBDManager.h"
#import "YKServiceShell.h"
#import "YKServiceLogger.h"

#define DB_PATH @"/private/var/mobile/Library/KeyboardServices/TextReplacements.db"

static BOOL lastStatusWasChinese = NO;

@interface YKKBDManager()
@end

@implementation YKKBDManager

-(instancetype)init {
    self = [super init];
    if (self) {
        [self ykkbd_addNotication];
    }
    return self;
}


//============================================================
// 监听业务
//============================================================
-(void)ykkbd_addNotication {
    
    // 监听中文开启
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    YKKBDProNotificationCallback,
                                    CFSTR("com.sky.ykpro.kbd.chinese.on"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    // 监听中文关闭
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    YKKBDProNotificationCallback,
                                    CFSTR("com.sky.ykpro.kbd.chinese.off"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
}

#pragma mark - 短语通知
static void YKKBDProNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    // 将 CFStringRef 转为 NSString 方便判断
    NSString *notificationName = (__bridge NSString *)name;
    
    if ([notificationName isEqualToString:@"com.sky.ykpro.kbd.chinese.on"]) {
        LOGI(@"检测到输入法切换：【中文】");
        lastStatusWasChinese = YES;
        // 在这里处理你的中文逻辑
    } else if ([notificationName isEqualToString:@"com.sky.ykpro.kbd.chinese.off"]) {
        LOGI(@"检测到输入法切换：【英文/其他】");
        lastStatusWasChinese = NO;
    }
}

#pragma mark - get
-(BOOL)isChineseInput {
    return lastStatusWasChinese;
}


//============================================================
// 输入文本
//============================================================
-(void)inputText:(NSString *)text {
    
    //等待实现
}


//============================================================
// 短语业务
//============================================================
#pragma mark - 添加短语
-(BOOL)addShortcut:(NSString *)shortcut phrase:(NSString *)phrase {
    
    LOGI(@"开始添加短语: %@ -> %@", shortcut, phrase);
    
    sqlite3 *db;
    if (sqlite3_open([DB_PATH UTF8String], &db) != SQLITE_OK) {
        LOGI(@"错误: 无法打开数据库文件: %@", DB_PATH);
        return NO;
    }
    LOGI(@"数据库打开成功");
    
    // 1. 动态获取表名
    NSString *tableName = [self getTableName:db];
    if (!tableName) {
        LOGI(@"错误: 找不到短语表");
        sqlite3_close(db);
        return NO;
    }
    LOGI(@"识别到当前系统表名: %@", tableName);
    
    
    // --- 新增逻辑：删除旧的重复快捷码 ---
    LOGI(@"正在清理旧的快捷码: %@", shortcut);
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE ZSHORTCUT = ?;", tableName];
    sqlite3_stmt *delStmt;
    if (sqlite3_prepare_v2(db, [deleteSql UTF8String], -1, &delStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(delStmt, 1, [shortcut UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(delStmt) == SQLITE_DONE) {
            int changes = sqlite3_changes(db);
            if (changes > 0) {
                LOGI(@"已成功覆盖（删除了 %d 条旧记录）", changes);
            }
        }
        sqlite3_finalize(delStmt);
    }
    // --------------------------------
    
    
    // 2. 检查字段兼容性 (动态探测)
    BOOL hasUniqueID   = [self column:@"ZUNIQUEID" existsInTable:tableName database:db];
    BOOL hasTimestamp  = [self column:@"ZTIMESTAMP" existsInTable:tableName database:db];
    BOOL hasNeedsCloud = [self column:@"ZNEEDSSAVETOCLOUD" existsInTable:tableName database:db];
    BOOL hasWasDeleted = [self column:@"ZWASDELETED" existsInTable:tableName database:db];
    BOOL hasUniqueName = [self column:@"ZUNIQUENAME" existsInTable:tableName database:db];
    
    LOGI(@"字段探测结果: UniqueID:%d, Time:%d, NeedsCloud:%d, Deleted:%d, UniqueName:%d",
         hasUniqueID, hasTimestamp, hasNeedsCloud, hasWasDeleted, hasUniqueName);
    
    int entID = [self getEntID:db forTable:tableName];
    LOGI(@"识别到 Z_ENT 实体 ID: %d", entID);
    
    // 3. 动态构建 SQL
    NSMutableArray *columns = [NSMutableArray arrayWithArray:@[@"Z_ENT", @"Z_OPT", @"ZPHRASE", @"ZSHORTCUT"]];
    NSMutableArray *placeholders = [NSMutableArray arrayWithArray:@[@"?", @"1", @"?", @"?"]];
    
    if (hasTimestamp) {
        [columns addObject:@"ZTIMESTAMP"];
        [placeholders addObject:@"?"];
    }
    if (hasUniqueID) {
        [columns addObject:@"ZUNIQUEID"];
        [placeholders addObject:@"?"];
    }
    if (hasNeedsCloud) {
        [columns addObject:@"ZNEEDSSAVETOCLOUD"];
        [placeholders addObject:@"1"]; // 直接硬编码为 1 (需要同步)
    }
    if (hasWasDeleted) {
        [columns addObject:@"ZWASDELETED"];
        [placeholders addObject:@"0"]; // 直接硬编码为 0 (未删除)
    }
    if (hasUniqueName) {
        [columns addObject:@"ZUNIQUENAME"];
        [placeholders addObject:@"?"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@);",
                     tableName,
                     [columns componentsJoinedByString:@", "],
                     [placeholders componentsJoinedByString:@", "]];
    
    LOGI(@"生成的 SQL 语句: %@", sql);
    
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        LOGI(@"错误: SQL 预处理失败: %s", sqlite3_errmsg(db));
        sqlite3_close(db);
        return NO;
    }
    
    // 4. 绑定变量
    int bindIdx = 1;
    sqlite3_bind_int(stmt, bindIdx++, entID);
    sqlite3_bind_text(stmt, bindIdx++, [phrase UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, bindIdx++, [shortcut UTF8String], -1, SQLITE_TRANSIENT);
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    if (hasTimestamp) {
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        sqlite3_bind_double(stmt, bindIdx++, now);
    }
    if (hasUniqueID) {
        sqlite3_bind_text(stmt, bindIdx++, [uuid UTF8String], -1, SQLITE_TRANSIENT);
    }
    if (hasUniqueName) {
        sqlite3_bind_text(stmt, bindIdx++, [uuid UTF8String], -1, SQLITE_TRANSIENT);
    }
    
    // 5. 执行插入
    BOOL success = NO;
    if (sqlite3_step(stmt) == SQLITE_DONE) {
        LOGI(@"数据库记录插入成功!");
        success = YES;
    } else {
        LOGI(@"错误: 执行插入失败: %s", sqlite3_errmsg(db));
    }
    sqlite3_finalize(stmt);
    
    // 6. 强制刷盘，防止数据停留在 wal
    LOGI(@"正在执行 PRAGMA wal_checkpoint...");
    sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", NULL, NULL, NULL);
    
    sqlite3_close(db);
    LOGI(@"数据库已关闭");
    
    // 修正权限
    [self fixPermissions];
    
    return success;
}


#pragma mark - 探测表名
-(NSString *)getTableName:(sqlite3 *)db {
    
    NSArray *candidates = @[@"ZTEXTREPLACEMENT", @"ZCLOUDTEXTREPLACEMENT", @"ZTEXTREPLACEMENTENTRY"];
    for (NSString *name in candidates) {
        NSString *query = [NSString stringWithFormat:@"SELECT name FROM sqlite_master WHERE type='table' AND name='%@';", name];
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                sqlite3_finalize(stmt);
                return name;
            }
        }
        sqlite3_finalize(stmt);
    }
    return nil;
}

#pragma mark - 探测字段是否存在
-(BOOL)column:(NSString *)columnName existsInTable:(NSString *)tableName database:(sqlite3 *)db {
    BOOL exists = NO;
    NSString *query = [NSString stringWithFormat:@"PRAGMA table_info(%@);", tableName];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *name = (const char *)sqlite3_column_text(stmt, 1);
            if (name && [[NSString stringWithUTF8String:name] isEqualToString:columnName]) {
                exists = YES;
                break;
            }
        }
    }
    sqlite3_finalize(stmt);
    return exists;
}

#pragma mark - 获取实体 ID (Z_ENT)
-(int)getEntID:(sqlite3 *)db forTable:(NSString *)tableName {
    int entID = 1;
    NSString *entityName = [tableName hasPrefix:@"Z"] ? [tableName substringFromIndex:1] : tableName;
    if ([tableName isEqualToString:@"ZTEXTREPLACEMENTENTRY"]) entityName = @"TextReplacement";
    if ([tableName isEqualToString:@"ZCLOUDTEXTREPLACEMENT"]) entityName = @"CloudTextReplacement";
    
    NSString *query = [NSString stringWithFormat:@"SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME LIKE '%%%@%%' LIMIT 1;", entityName];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            entID = sqlite3_column_int(stmt, 0);
        }
    }
    sqlite3_finalize(stmt);
    return entID;
}

#pragma mark - 修改权限
-(void)fixPermissions {
    
    LOGI(@"正在修正数据库文件权限为 mobile:mobile (501)...");
    NSDictionary *attrs = @{NSFilePosixPermissions: @(0644), NSFileOwnerAccountID: @(501), NSFileGroupOwnerAccountID: @(501)};
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *ext in @[@"", @"-wal", @"-shm"]) {
        NSString *p = [DB_PATH stringByAppendingString:ext];
        if ([fm fileExistsAtPath:p]) {
            NSError *err = nil;
            [fm setAttributes:attrs ofItemAtPath:p error:&err];
            if (err) {
                LOGI(@"权限修正失败: %@, 错误: %@", p, err.localizedDescription);
            } else {
                LOGI(@"权限修正成功: %@", p);
            }
        }
    }
}

#pragma mark - 强制重启生效
-(void)applyChanges {
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.sky.ykpro.kbd.updateCache"),
                                         NULL,
                                         NULL,
                                         YES);
}
@end

//
//  YKFileTransferManager.m
//  Created on 2025/9/27
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKServiceLogger.h"
#import "YKFileUploadSocket.h"
#import "YKFileDownloadSocket.h"
#import "YKFileTransferManager.h"


@interface YKFileTransferManager()
@property(nonatomic, strong) NSMutableArray <YKFileDownloadSocket *> * fileDownloadSocketArray;//文件下载数组
@property(nonatomic, strong) NSMutableArray <YKFileUploadSocket *> *fileUploadSocketArray;//文件上传数组
@property(nonatomic, strong) dispatch_queue_t downloadManagerQueue;  // 下载队列
@property(nonatomic, strong) dispatch_queue_t uploadManagerQueue;    // 上传队列
@end

@implementation YKFileTransferManager

-(instancetype)init {
    self = [super init];
    if (self) {
        
        _fileUploadSocketArray = [NSMutableArray array];
        _fileDownloadSocketArray = [[NSMutableArray alloc] init];
        _downloadManagerQueue = dispatch_queue_create("com.sky.yk.fileDownloadManager", DISPATCH_QUEUE_SERIAL);
        _uploadManagerQueue = dispatch_queue_create("com.sky.yk.fileUploadManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


#pragma mark - 添加文件下载
-(void)addFileDownloadModel:(YKFileDownloadModel *)model portCallback:(void(^)(UInt16 port))portCallback completion:(nonnull void (^)(BOOL, NSString * _Nonnull))completion
{
    dispatch_async(_downloadManagerQueue, ^{
        
        
        for (YKFileDownloadSocket *socket in self.fileDownloadSocketArray) {
            if ([socket.model.path isEqualToString:model.path]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(NO, @"已存在相同文件正在处理");
                    }
                });
                return;
            }
        }
        
        __weak typeof(self) weakSelf = self;
        YKFileDownloadSocket *fileDownloadSocket = [[YKFileDownloadSocket alloc] initWithModel:model portCallback:portCallback completion:^(BOOL success, NSString *msg) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(success, msg);
            });
            
            dispatch_async(weakSelf.downloadManagerQueue, ^{
                YKFileDownloadSocket *removeObj = nil;
                for (YKFileDownloadSocket *item in weakSelf.fileDownloadSocketArray)
                {
                    // 这里移除逻辑依然使用 identity，确保精准移除
                    if ([item.model.identity isEqualToString:model.identity])
                    {
                        removeObj = item;
                        break;
                    }
                }
                if (removeObj) {
                    [weakSelf.fileDownloadSocketArray removeObject:removeObj];
                }
            });
        }];
        
        [self.fileDownloadSocketArray addObject:fileDownloadSocket];
        [fileDownloadSocket start];
    });
}

#pragma mark - 添加文件上传
-(void)addFileUploadModel:(YKFileUploadModel *)model
             portCallback:(void(^)(UInt16 port))portCallback
               completion:(void (^)(BOOL success, NSString *msg))completion
{
    __weak typeof(self) weakSelf = self;
    __weak YKFileUploadSocket *weakUploadSocket = nil;
    
    YKFileUploadSocket *fileUploadSocket =
    [[YKFileUploadSocket alloc] initWithModel:model portCallback:portCallback completion:^(BOOL success, NSString *msg) {
        
        dispatch_async(weakSelf.uploadManagerQueue, ^{
            
            YKFileUploadSocket *removeObj;
            for (YKFileUploadSocket *item in weakSelf.fileUploadSocketArray) {
                if ([item.model.identity isEqualToString:model.identity]) {
                    removeObj = item;
                    break;
                }
            }
            [weakSelf.fileUploadSocketArray removeObject:removeObj];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success, msg);
        });
    }];
    
    weakUploadSocket = fileUploadSocket;
    
    dispatch_async(_uploadManagerQueue, ^{
        [weakSelf.fileUploadSocketArray addObject:fileUploadSocket];
        [fileUploadSocket start];
    });
}
@end

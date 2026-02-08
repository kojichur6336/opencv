//
//  YKPictureManager.m
//  YKService
//
//  Created by liuxiaobin on 2025/10/10.
//

#import "YKConstants.h"
#import <Photos/Photos.h>
#import "YKServiceLogger.h"
#import "YKPictureManager.h"
#import <YKZipKit/SSZipArchive.h>

@implementation YKPictureManager

#pragma mark - 解压图片处理
+(void)decompressionProcess:(NSString *)fullPath completion:(void (^)(BOOL, NSString * _Nonnull))completion
{
    NSString *extension = [[fullPath pathExtension] lowercaseString];
    
    if ([@[@"jpg", @"jpeg", @"png", @"bmp", @"gif", @"webp"] containsObject:extension]) {
        
        [self savePhotos:fullPath completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                completion(success, @"成功");
            } else {
                completion(success, error.localizedDescription);
            }
        }];
    } else if ([@[@"mp4", @"mov", @"avi", @"mkv", @"flv", @"wmv"] containsObject:extension]) {
        
        [self saveVideo:fullPath completionHandler:^(BOOL success, NSError * _Nonnull error) {
            if (success) {
                completion(success, @"成功");
            } else {
                completion(success, error.localizedDescription);
            }
        }];
    }
}


#pragma mark - 保存图片
+(void)savePhotos:(NSString *)path completionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler {
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:path]];
    } completionHandler:completionHandler];
}

#pragma mark - 保存视频
+(void)saveVideo:(NSString *)path completionHandler:(nullable void (^)(BOOL, NSError * _Nullable))completionHandler
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:path]];
    } completionHandler:completionHandler];
}

#pragma mark - 删除所有的照片
+(void)deleteAllPhotos:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler {
    
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:nil];
    
    NSMutableArray *assetsToDelete = [NSMutableArray array];
    
    [allPhotos enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [assetsToDelete addObject:asset];
    }];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assetsToDelete];
    } completionHandler: completionHandler];
}
@end

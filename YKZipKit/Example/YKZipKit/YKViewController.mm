//
//  YKViewController.m
//  YKZipKit
//
//  Created by liuxiaobin on 09/29/2025.
//  Copyright (c) 2025 liuxiaobin. All rights reserved.
//


#import "YKViewController.h"
#import <YKZipKit/SSZipArchive.h>

@interface YKViewController ()

@end

@implementation YKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    
    // 获取应用包内的 zip 文件路径
       NSString *zipFileName = @"xxx.zip";  // 你的 zip 文件名
       NSString *zipFilePath = [[NSBundle mainBundle] pathForResource:zipFileName ofType:nil];
       
       // 获取本地沙盒路径（这里使用 Documents 目录，你可以根据需要选择其他目录）
       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
       NSString *destinationPath = [paths.firstObject stringByAppendingPathComponent:@"unzipped"];

       // 创建目标文件夹，如果没有的话
       NSFileManager *fileManager = [NSFileManager defaultManager];
       if (![fileManager fileExistsAtPath:destinationPath]) {
           NSError *error = nil;
           [fileManager createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:&error];
           if (error) {
               NSLog(@"创建目标文件夹失败: %@", error.localizedDescription);
               return;
           }
       }
       
       // 解压操作
       BOOL success = [SSZipArchive unzipFileAtPath:zipFilePath
                                      toDestination:destinationPath
                                          overwrite:YES
                                           password:nil
                                              error:nil];
       
       if (success) {
           NSLog(@"解压成功，文件已存储在: %@", destinationPath);
       } else {
           NSLog(@"解压失败");
       }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

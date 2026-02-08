//
//  YKScanViewController.m
//  YKApp
//
//  Created by liuxiaobin on 2025/10/16.
//


#import "YKColor.h"
#import "YKAppLogger.h"
#import "YKHeaderView.h"
#import "YKScanViewController.h"
#import <AVFoundation/AVFoundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface YKScanViewController ()<AVCaptureMetadataOutputObjectsDelegate, YKHeaderViewDelegate>
@property(nonatomic, strong) YKHeaderView *headerView;//头部视图
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDevice *device;
@property(nonatomic, strong) AVCaptureDeviceInput *input;
@property(nonatomic, strong) AVCaptureMetadataOutput *output;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic, strong) UIView *scanLine;
@property(nonatomic, strong) UIView *scanAreaView;
@property(nonatomic, assign) BOOL isScanningUp;
@end

@implementation YKScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self configView];
    [self configLocation];
    [self requestCameraPermission];
}

#pragma mark - 配置视图
-(void)configView {
    
    [self.view addSubview:self.headerView];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:44 + UIApplication.sharedApplication.statusBarFrame.size.height],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        
    ]];
}

#pragma mark - 请求相机权限
-(void)requestCameraPermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status == AVAuthorizationStatusNotDetermined) {
        // 用户还没有做出选择，弹出权限请求框
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    // 用户允许权限
                    [self setupCamera];
                } else {
                    // 用户拒绝权限
                    [self showPermissionDeniedAlert];
                }
            });
        }];
    } else if (status == AVAuthorizationStatusAuthorized) {
        // 用户已授权，直接初始化摄像头
        [self setupCamera];
    } else {
        // 用户已拒绝权限，显示提示信息
        [self showPermissionDeniedAlert];
    }
}

#pragma mark - 显示权限弹窗提示
-(void)showPermissionDeniedAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"相机权限未授权"
                                                                             message:@"请在(设置->隐私->相机)中授权应用使用相机。"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 设置相机
-(void)setupCamera {
    
    // 设置设备
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 创建输入
    NSError *error = nil;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    if (error) {
        LOGI(@"Error setting input device: %@", error.localizedDescription);
        return;
    }
    
    // 创建输出
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.output setRectOfInterest:CGRectMake(0, 0, 1, 1)]; // 设置扫描区域为全屏
    
    // 创建会话
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    
    // 设置元数据类型，扫描二维码
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]; // 支持扫描二维码
    
    // 创建预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    // 获取头部视图的高度，确保预览层不会被头部视图遮挡
    CGFloat headerHeight = 44 + UIApplication.sharedApplication.statusBarFrame.size.height;  // 头部视图的高度（包括状态栏）
    // 更新预览层的位置，确保它位于头部视图下方
    self.previewLayer.frame = CGRectMake(0, headerHeight, self.view.frame.size.width, self.view.frame.size.height - headerHeight);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    // 启动会话
    [self.session startRunning];
    [self setupScanLine];
}


#pragma mark - 设置线
-(void)setupScanLine {
    
    CGFloat scanAreaWidth = self.view.frame.size.width / 2;
    CGFloat scanAreaHeight = scanAreaWidth;  // 保证正方形
    CGFloat scanAreaX = self.view.frame.size.width / 4;
    CGFloat scanAreaY = self.view.frame.size.height / 4;
    
    // 创建扫描框
    self.scanAreaView = [[UIView alloc] initWithFrame:CGRectMake(scanAreaX, scanAreaY, scanAreaWidth, scanAreaHeight)];
    self.scanAreaView.layer.borderColor = UIColor.mainColor.CGColor;
    self.scanAreaView.layer.borderWidth = 2.0;
    [self.view addSubview:self.scanAreaView];
    
    // 创建扫描线
    self.scanLine = [[UIView alloc] initWithFrame:CGRectMake(scanAreaX, scanAreaY - 2, scanAreaWidth, 2)];
    self.scanLine.backgroundColor = UIColor.mainColor;
    [self.view addSubview:self.scanLine];
    
    // 开始扫描线的动画
    [self startScanLineAnimation];
}

-(void)startScanLineAnimation
{
    CGFloat scanAreaY = self.scanAreaView.frame.origin.y;
    CGFloat scanAreaHeight = self.scanAreaView.frame.size.height;
    self.isScanningUp = YES;
    
    [UIView animateWithDuration:2.0
                          delay:0
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
        if (self.isScanningUp) {
            self.scanLine.frame = CGRectMake(self.scanLine.frame.origin.x, scanAreaY + scanAreaHeight - 4, self.scanLine.frame.size.width, self.scanLine.frame.size.height);
        } else {
            self.scanLine.frame = CGRectMake(self.scanLine.frame.origin.x, scanAreaY - 2, self.scanLine.frame.size.width, self.scanLine.frame.size.height);
        }
        self.isScanningUp = !self.isScanningUp;
    } completion:nil];
}




#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureMetadataOutput *)output
didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *scannedValue = metadataObject.stringValue;
        
        [self.session stopRunning];
        [self.scanLine.layer removeAllAnimations];
        //AudioServicesPlaySystemSound(1022);
        [self.delegate ykScanViewController:self qrcode:scannedValue];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - YKHeaderViewDelegate
-(void)ykHeaderView:(YKHeaderView *)view backButton:(UIControl *)backButton {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - lazy
-(YKHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[YKHeaderView alloc] init];
        _headerView.delegate = self;
        _headerView.titleLabel.text = @"扫一扫";
        _headerView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _headerView;
}

#pragma mark - 释放
-(void)dealloc {
    LOGI(@"释放了");
}
@end


#pragma clang diagnostic pop

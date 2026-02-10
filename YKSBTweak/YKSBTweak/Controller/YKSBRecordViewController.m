//
//  YKSBRecordViewController.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/12/6.
//

#import <UIKit/UIKit.h>
#import "YKSBRecordViewController.h"

@class YKSBRecordWindow;

/// 静态录制窗口
static YKSBRecordWindow *recordWindow = nil;

/// MARK - 录制倒计时窗口
@interface YKSBRecordWindow : UIWindow
@property(nonatomic, copy) void (^completionBlock)(void);  // 完成后的回调block
@property(nonatomic, strong) UIViewController *viewController;//控制器
@property(nonatomic, strong) UILabel *countdownLabel;//倒计时标签
@property(nonatomic, assign) NSInteger countdownValue;//倒计时秒数
@property(nonatomic, strong) NSTimer *timer;//时间
@end

@implementation YKSBRecordWindow

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.windowLevel = UIWindowLevelAlert + 1;
        self.countdownValue = 3;
        [self configView];
        [self startCountdown];
    }
    return self;
}

#pragma mark - 配置视图
-(void)configView {
    
    _viewController = [[UIViewController alloc] init];
    // 背景稍微加深一点，提升对比度
    _viewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    
    // 创建倒计时Label
    _countdownLabel = [[UILabel alloc] init];
    // 使用等宽数字字体，防止倒计时数字宽度跳变
    _countdownLabel.font = [UIFont monospacedDigitSystemFontOfSize:100 weight:UIFontWeightHeavy];
    _countdownLabel.textColor = [UIColor whiteColor];
    
    // 添加阴影，增加立体感
    _countdownLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _countdownLabel.layer.shadowOffset = CGSizeMake(0, 4);
    _countdownLabel.layer.shadowOpacity = 0.6;
    _countdownLabel.layer.shadowRadius = 8;
    
    _countdownLabel.textAlignment = NSTextAlignmentCenter;
    _countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownValue];
    _countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_viewController.view addSubview:self.countdownLabel];
    
    // 添加倒计时Label的 Auto Layout 约束
    [NSLayoutConstraint activateConstraints:@[
        [self.countdownLabel.centerXAnchor constraintEqualToAnchor:_viewController.view.centerXAnchor],
        [self.countdownLabel.centerYAnchor constraintEqualToAnchor:_viewController.view.centerYAnchor]
    ]];
    
    self.rootViewController = _viewController;
    
    // 初始显示的"3"也执行一次动画
    [self animateLabelBounce];
}

#pragma mark - 开始倒计时
-(void)startCountdown {
    // 每1秒更新倒计时
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
}

#pragma mark - 倒计时逻辑
-(void)updateCountdown {
    // 减少倒计时
    self.countdownValue--;
    
    if (self.countdownValue > 0) {
        // 更新数字
        self.countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownValue];
        // 执行弹性动画
        [self animateLabelBounce];
    } else {
        // 倒计时结束
        [self.timer invalidate];
        self.timer = nil;
        
        self.countdownLabel.font = [UIFont boldSystemFontOfSize:60];
        self.countdownLabel.text = @"开始录制";
        
        // 执行结束爆发动画
        [self startStartAnimation];
    }
}

#pragma mark - 数字跳动动画 (重击效果)
- (void)animateLabelBounce {
    // 1. 初始状态：巨大且透明 (模拟从屏幕外砸向屏幕)
    self.countdownLabel.transform = CGAffineTransformMakeScale(2.5, 2.5);
    self.countdownLabel.alpha = 0.0;
    
    // 2. 弹性复位 (带点震动的重击感)
    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.6  // 阻尼稍微调高一点，让撞击感更实
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.countdownLabel.transform = CGAffineTransformIdentity; // 恢复原大小
        self.countdownLabel.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 结束动画 (蓄力 -> 闪光爆发)
- (void)startStartAnimation {
    // 1. 蓄力阶段：文字变红，稍微缩小
    self.countdownLabel.textColor = [UIColor systemRedColor]; // 变成录制红
    
    [UIView animateWithDuration:0.15 animations:^{
        self.countdownLabel.transform = CGAffineTransformMakeScale(0.7, 0.7);
    } completion:^(BOOL finished) {
        
        // 2. 爆发阶段：模拟闪光灯效果 + 文字炸开
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            
            // 背景瞬间变亮（闪光效果）
            self.viewController.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            
            // 文字极速放大并消失
            self.countdownLabel.transform = CGAffineTransformMakeScale(5.0, 5.0);
            self.countdownLabel.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            
            // 3. 整体快速隐去，把控制权交给回调
            [UIView animateWithDuration:0.15 animations:^{
                self.alpha = 0.0;
            } completion:^(BOOL finished) {
                // 清理工作
                if (self.completionBlock) {
                    self.completionBlock();
                }
                [recordWindow resignKeyWindow];
                recordWindow.hidden = YES;
                recordWindow = nil;
            }];
        }];
    }];
}

#pragma mark - 停止倒计时
-(void)stop {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}
@end


@implementation YKSBRecordViewController

#pragma mark - 显示
+(void)show:(void (^)(void))completion
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    YKSBRecordWindow * window = [[YKSBRecordWindow alloc]
                                 initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    UIWindowScene *mainScene = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes)
    {
        if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive)
        {
            mainScene = scene;
            break;
        }
    }
    
    // 初始状态设置
    window.alpha = 0.0;
    window.windowScene = mainScene;
    [window makeKeyAndVisible];
    
    window.completionBlock = completion;
    recordWindow = window;
    
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        window.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 隐藏
+(void)hidden {
    
    if (recordWindow) {
        
        [recordWindow stop];
        
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            recordWindow.alpha = 0.0;
            recordWindow.transform = CGAffineTransformMakeScale(1.1, 1.1); // 隐藏时稍微放大一点，看起来更顺滑
        }
                         completion:^(BOOL finished) {
            [recordWindow resignKeyWindow];
            recordWindow.hidden = YES;
            recordWindow = nil;
        }];
    }
}
@end
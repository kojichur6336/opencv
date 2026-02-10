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
    
    // 升级：使用高斯模糊背景，替代纯色背景，更有质感
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = [UIScreen mainScreen].bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurView.alpha = 0.95; 
    [_viewController.view addSubview:blurView];
    
    // 创建倒计时Label
    _countdownLabel = [[UILabel alloc] init];
    // 升级：使用最粗的字体 (Black)，视觉冲击力更强
    _countdownLabel.font = [UIFont systemFontOfSize:120 weight:UIFontWeightBlack];
    _countdownLabel.textColor = [UIColor whiteColor];
    
    // 升级：加强阴影效果，营造浮空立体感
    _countdownLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _countdownLabel.layer.shadowOffset = CGSizeMake(0, 5);
    _countdownLabel.layer.shadowOpacity = 0.8;
    _countdownLabel.layer.shadowRadius = 12;
    
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
        
        // 升级：颜色随倒计时变化，增加紧迫感
        if (self.countdownValue == 2) {
            self.countdownLabel.textColor = [UIColor systemYellowColor];
        } else if (self.countdownValue == 1) {
            self.countdownLabel.textColor = [UIColor systemOrangeColor];
        }
        
        // 执行弹性动画
        [self animateLabelBounce];
    } else {
        // 倒计时结束
        [self.timer invalidate];
        self.timer = nil;
        
        self.countdownLabel.font = [UIFont systemFontOfSize:80 weight:UIFontWeightBlack];
        self.countdownLabel.textColor = [UIColor systemRedColor]; // 最终变为红色
        self.countdownLabel.text = @"REC"; // 简洁有力
        
        // 执行结束爆发动画
        [self startStartAnimation];
    }
}

#pragma mark - 数字跳动动画 (重击 + 旋转 + 震动)
- (void)animateLabelBounce {
    // 升级：添加触觉反馈 (需要真机)
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        [feedback prepare];
        [feedback impactOccurred];
    }

    // 1. 初始状态：巨大、透明、带一点随机旋转 (模拟撞击感)
    CGFloat rotationAngle = (arc4random_uniform(20) - 10) * (M_PI / 180.0); // -10度到10度随机旋转
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(3.5, 3.5);
    CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(rotationAngle);
    
    self.countdownLabel.transform = CGAffineTransformConcat(scaleTransform, rotateTransform);
    self.countdownLabel.alpha = 0.0;
    
    // 2. 弹性复位
    [UIView animateWithDuration:0.7
                          delay:0
         usingSpringWithDamping:0.55  // 较强弹性
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.countdownLabel.transform = CGAffineTransformIdentity; // 恢复正位
        self.countdownLabel.alpha = 1.0;
    } completion:nil];
}

#pragma mark - 结束动画 (蓄力 -> 闪光 + 炸裂)
- (void)startStartAnimation {
    // 升级：成功提示震动
    if (@available(iOS 10.0, *)) {
        UINotificationFeedbackGenerator *feedback = [[UINotificationFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
    }

    // 1. 蓄力阶段：文字瞬间缩小，仿佛在积蓄能量
    [UIView animateWithDuration:0.15 animations:^{
        self.countdownLabel.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) {
        
        // 2. 爆发阶段：模拟闪光灯效果 + 文字炸裂飞出
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            
            // 背景瞬间变白（闪光效果）
            self.viewController.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            // 隐藏模糊层
            for (UIView *subview in self.viewController.view.subviews) {
                if ([subview isKindOfClass:[UIVisualEffectView class]]) {
                    subview.alpha = 0.0;
                }
            }
            
            // 文字极速放大并带旋转消失
            CGAffineTransform bigScale = CGAffineTransformMakeScale(6.0, 6.0);
            CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2 / 2); // 旋转45度
            self.countdownLabel.transform = CGAffineTransformConcat(bigScale, rotate);
            self.countdownLabel.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            
            // 3. 快速隐去窗口，触发回调
            if (self.completionBlock) {
                self.completionBlock();
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                self.alpha = 0.0;
            } completion:^(BOOL finished) {
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
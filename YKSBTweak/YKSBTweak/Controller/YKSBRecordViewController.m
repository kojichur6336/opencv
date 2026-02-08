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
    _viewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    
    // 创建倒计时Label
    _countdownLabel = [[UILabel alloc] init];
    _countdownLabel.font = [UIFont boldSystemFontOfSize:80];
    _countdownLabel.textColor = [UIColor whiteColor];
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
}

#pragma mark - 开始倒计时
-(void)startCountdown {
    
    // 每1秒更新倒计时
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
}

#pragma mark - 倒计时
-(void)updateCountdown {
    
    // 减少倒计时
    self.countdownValue--;
    self.countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownValue];
    
    // 倒计时结束，停止定时器并显示“开始”
    if (self.countdownValue == 0) {
        [self.timer invalidate];
        self.countdownLabel.text = @"开始录制";
        [self startStartAnimation];
    }
}

#pragma mark - 倒计时
- (void)startStartAnimation {
    // 倒计时结束后，做一个缩小到消失的动画效果
    [UIView animateWithDuration:0.5 animations:^{
        self.countdownLabel.transform = CGAffineTransformMakeScale(0.4, 0.4);  // 缩小到消失
    } completion:^(BOOL finished) {
        self.countdownLabel.alpha = 0;  // 完全透明
        self.completionBlock();
        [recordWindow resignKeyWindow];
        recordWindow.hidden = YES;
        recordWindow = nil;
    }];
}

#pragma mark - 停止倒计时
-(void)stop {
    [self.timer invalidate];
    self.timer = nil;
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
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        window.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 隐藏
+(void)hidden {
    
    if (recordWindow) {
    
        [recordWindow stop];
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            recordWindow.alpha = 0.0;
        }
                         completion:^(BOOL finished) {
            [recordWindow resignKeyWindow];
            recordWindow.hidden = YES;
            recordWindow = nil;
        }];
    }
}
@end

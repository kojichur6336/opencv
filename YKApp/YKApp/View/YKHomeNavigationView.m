//
//  YKAppHeaderView.m
//  Created on 2025/10/10
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKColor.h"
#import "YKAppLogger.h"
#import "YKHomeNavigationView.h"

@interface YKHomeNavigationView()
@property(nonatomic, strong) UIControl *homeControl;//首页视图
@property(nonatomic, strong) UIControl *logControl;  //日志视图
@property(nonatomic, strong) UIControl *scanControl;//扫一扫视图
@property(nonatomic, strong) UILabel *titleLabel;//标题标签
@end

@implementation YKHomeNavigationView

-(instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.mainColor;
        [self configView];
        [self configLocation];
    }
    return self;
}

#pragma mark - 配置视图
-(void)configView {
    [self addSubview:self.homeControl];
    [self addSubview:self.titleLabel];
    [self addSubview:self.logControl];
    [self addSubview:self.scanControl];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.homeControl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [self.homeControl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.homeControl.centerYAnchor],
        
        
        [self.scanControl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
        [self.scanControl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.logControl.trailingAnchor constraintEqualToAnchor:self.scanControl.leadingAnchor constant:-4],
        [self.logControl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

#pragma mark - 点击首页
-(void)handleHomeTap {
    LOGI(@"点击了首页");
    [self.delegate ykNavigationView:self home:self.homeControl];
}

#pragma mark - 扫一扫
-(void)handleScanTap {
    LOGI(@"点击了扫一扫");
    [self.delegate ykNavigationView:self qrcode:self.scanControl];
}

#pragma mark - 点击日志
-(void)handleLogTap {
    LOGI(@"点击了日志");
    if ([self.delegate respondsToSelector:@selector(ykNavigationView:log:)]) {
        [self.delegate ykNavigationView:self log:self.logControl];
    }
}


#pragma mark - lazy
-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.backgroundColor = UIColor.clearColor;
        _titleLabel.text = @"远控Pro";
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _titleLabel;
}

-(UIControl *)homeControl {
    if (!_homeControl) {
        _homeControl = [[UIControl alloc] init];
        _homeControl.backgroundColor = UIColor.clearColor;
        _homeControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 点击事件
        [_homeControl addTarget:self action:@selector(handleHomeTap) forControlEvents:UIControlEventTouchUpInside];
        
        // 图标
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"house.fill"]];
        imageView.tintColor = UIColor.whiteColor;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_homeControl addSubview:imageView];
        
        [NSLayoutConstraint activateConstraints:@[
            [imageView.centerXAnchor constraintEqualToAnchor:_homeControl.centerXAnchor],
            [imageView.centerYAnchor constraintEqualToAnchor:_homeControl.centerYAnchor],
            [imageView.widthAnchor constraintEqualToConstant:28],
            [imageView.heightAnchor constraintEqualToConstant:28]
        ]];
        
        [_homeControl.widthAnchor constraintEqualToConstant:44].active = YES;
        [_homeControl.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    return _homeControl;
}

-(UIControl *)scanControl
{
    if (!_scanControl)
    {
        _scanControl = [[UIControl alloc] init];
        _scanControl.backgroundColor = UIColor.clearColor;
        _scanControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_scanControl addTarget:self action:@selector(handleScanTap) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        UIImage *image = nil;
        if (@available(iOS 14.0, *)) {
            image = [UIImage systemImageNamed:@"qrcode.viewfinder"];
        } else {
            image = [UIImage systemImageNamed:@"qrcode"];
        }
        imageView.image = image;
        imageView.tintColor = UIColor.whiteColor;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_scanControl addSubview:imageView];
        
        [NSLayoutConstraint activateConstraints:@[
            [imageView.centerXAnchor constraintEqualToAnchor:_scanControl.centerXAnchor],
            [imageView.centerYAnchor constraintEqualToAnchor:_scanControl.centerYAnchor],
            [imageView.widthAnchor constraintEqualToConstant:28],
            [imageView.heightAnchor constraintEqualToConstant:28]
        ]];
        
        [_scanControl.widthAnchor constraintEqualToConstant:44].active = YES;
        [_scanControl.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    return _scanControl;
}

-(UIControl *)logControl {
    if (!_logControl) {
        _logControl = [[UIControl alloc] init];
        _logControl.backgroundColor = UIColor.clearColor;
        _logControl.translatesAutoresizingMaskIntoConstraints = NO;
        _logControl.hidden = YES;
        [_logControl addTarget:self action:@selector(handleLogTap) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage systemImageNamed:@"doc.text.fill"];
        imageView.tintColor = UIColor.whiteColor;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_logControl addSubview:imageView];
        
        [NSLayoutConstraint activateConstraints:@[
            [imageView.centerXAnchor constraintEqualToAnchor:_logControl.centerXAnchor],
            [imageView.centerYAnchor constraintEqualToAnchor:_logControl.centerYAnchor],
            [imageView.widthAnchor constraintEqualToConstant:26], // 略小一点显得精致
            [imageView.heightAnchor constraintEqualToConstant:26]
        ]];
        
        [_logControl.widthAnchor constraintEqualToConstant:44].active = YES;
        [_logControl.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    return _logControl;
}

@end

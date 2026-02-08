//
//  YKHeaderView.m
//  YKApp
//
//  Created by liuxiaobin on 2025/10/16.
//

#import "YKColor.h"
#import "YKHeaderView.h"


@interface YKHeaderView()
@property(nonatomic, strong) UIControl *backButton;
@end

@implementation YKHeaderView

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
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.backButton];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.backButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [self.backButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.backButton.centerYAnchor],
    ]];
}


#pragma mark - backButtonTapped
-(void)backButtonTapped {
    
    [self.delegate ykHeaderView:self backButton:self.backButton];
}

#pragma mark - lazy
-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.backgroundColor = UIColor.clearColor;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _titleLabel;
}
-(UIControl *)backButton {
    if (!_backButton) {
        
        _backButton = [[UIControl alloc] init];
        _backButton.backgroundColor = UIColor.clearColor;
        _backButton.translatesAutoresizingMaskIntoConstraints = NO;

        // 点击事件
        [_backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];

        
        UIImageView *imageView;
        if (@available(iOS 15.0, *)) {
            imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.backward"]];
        } else {
            imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"]];
        }
        imageView.tintColor = UIColor.whiteColor;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_backButton addSubview:imageView];

        [NSLayoutConstraint activateConstraints:@[
            [imageView.centerXAnchor constraintEqualToAnchor:_backButton.centerXAnchor],
            [imageView.centerYAnchor constraintEqualToAnchor:_backButton.centerYAnchor],
            [imageView.widthAnchor constraintEqualToConstant:28],
            [imageView.heightAnchor constraintEqualToConstant:28]
        ]];

        [_backButton.widthAnchor constraintEqualToConstant:44].active = YES;
        [_backButton.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    return _backButton;
}
@end

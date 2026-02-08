//
//  YKHomeHeaderFooterView.m
//  YKApp
//
//  Created by liuxiaobin on 2026/1/3.
//

#import "YKHomeHeaderFooterView.h"

@implementation YKHomeHeaderFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor clearColor];
        [self configView];
        [self configLocation];
    }
    return self;
}


#pragma mark - 配置视图
-(void)configView {
    [self.contentView addSubview:self.titleLabel];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor: self.contentView.bottomAnchor constant:-8],
    ]];
}

#pragma mark - lazy
-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = UIColor.clearColor;
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _titleLabel.textColor = UIColor.blackColor;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _titleLabel;
}

@end

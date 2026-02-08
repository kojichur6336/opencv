//
//  YKDeviceCell.m
//  YKApp
//
//  Created by liuxiaobin on 2026/1/4.
//

#import "YKDeviceCell.h"

@interface YKDeviceCell()
@property(nonatomic, strong) UIView *stackView;//容器视图
@end

@implementation YKDeviceCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        //self.contentView.backgroundColor = UIColor.redColor;
        [self configView];
        [self configLocation];
    }
    return self;
}

#pragma mark - 配置视图
-(void)configView {
    [self.contentView addSubview:self.stackView];
    [self.stackView addSubview:self.nameLabel];
    [self.stackView addSubview:self.valueLabel];
    [self.contentView addSubview:self.tipLabel];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintEqualToConstant:50];
    heightConstraint.priority = UILayoutPriorityRequired - 1;
    heightConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.stackView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor multiplier:0.7],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.stackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        
        
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.stackView.topAnchor constant:8],
    
        [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.valueLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
        [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:-8],
        
        [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
        [self.tipLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
    
}

#pragma mark - lazy
-(UIView *)stackView {
    if (!_stackView) {
        _stackView = [[UIView alloc] init];
        _stackView.backgroundColor = UIColor.clearColor;
        _stackView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _stackView;
}


-(UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColor.blackColor;
        _nameLabel.font = [UIFont systemFontOfSize:16];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _nameLabel;
}

-(UILabel *)valueLabel {
    if (!_valueLabel) {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textColor = UIColor.grayColor;
        _valueLabel.font = [UIFont systemFontOfSize:16];
        _valueLabel.numberOfLines = 0;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _valueLabel;
}

-(UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.38 alpha:1.0];
        _tipLabel.font = [UIFont boldSystemFontOfSize:18];
        _tipLabel.text = @"已连接";
        _tipLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _tipLabel;
}
@end

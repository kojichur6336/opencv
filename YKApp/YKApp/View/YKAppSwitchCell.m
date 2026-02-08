//
//  YKAppSwitchCell.m
//  YKApp
//
//  Created by liuxiaobin on 2025/12/27.
//

#import "YKColor.h"
#import "YKAppSwitchCell.h"

@implementation YKAppSwitchCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self configView];
        [self configLocation];
    }
    return self;
}

#pragma mark - 配置视图
-(void)configView {
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.switchView];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintEqualToConstant:50];
    heightConstraint.priority = UILayoutPriorityRequired - 1;
    heightConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        
        
        [self.switchView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.switchView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.switchView.widthAnchor constraintEqualToConstant:44],
        [self.switchView.heightAnchor constraintEqualToConstant:30],
    ]];
}


#pragma mark - 切换
-(void)eventForSwitch {
    [self.delegate appSwitchCell:self name:self.nameLabel.text didChangeStatus:self.switchView.on];
}

#pragma mark - lazy
-(UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColor.blackColor;
        _nameLabel.font = [UIFont systemFontOfSize:18];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _nameLabel;
}

-(UISwitch *)switchView {
    if (!_switchView) {
        _switchView = [[UISwitch alloc] init];
        [_switchView addTarget:self action:@selector(eventForSwitch) forControlEvents:UIControlEventValueChanged];
        _switchView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _switchView;
}
@end

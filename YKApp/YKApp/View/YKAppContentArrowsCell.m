//
//  YKAppContentArrowsCell.m
//  Created on 2025/10/15
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKAppContentArrowsCell.h"

@implementation YKAppContentArrowsCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self configView];
        [self configLocation];
    }
    return self;
}

#pragma mark - 配置视图
-(void)configView {
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.valueLabel];
}

#pragma mark - 配置位置
-(void)configLocation {
    
    NSLayoutConstraint *heightConstraint = [self.contentView.heightAnchor constraintEqualToConstant:50];
    heightConstraint.priority = UILayoutPriorityRequired - 1;
    heightConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        
        
        [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-6],
        [self.valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.nameLabel.trailingAnchor constant:12],
        [self.valueLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
    
    
    [self.nameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];
    [self.valueLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                    forAxis:UILayoutConstraintAxisHorizontal];

    [self.nameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                      forAxis:UILayoutConstraintAxisHorizontal];
    [self.valueLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                      forAxis:UILayoutConstraintAxisHorizontal];
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

-(UILabel *)valueLabel {
    if (!_valueLabel) {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textColor = UIColor.grayColor;
        _valueLabel.font = [UIFont systemFontOfSize:15];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.numberOfLines = 0;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _valueLabel;
}
@end


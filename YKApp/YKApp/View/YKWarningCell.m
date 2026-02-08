//
//  YKWarningCell.m
//  Created on 2026/1/13
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import "YKWarningCell.h"

@implementation YKWarningCell

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
}

#pragma mark - 配置位置
-(void)configLocation {
    
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16]
    ]];
    
    // 抗压缩/抗拉伸优先级（通常多行 Label 建议设置）
    [self.nameLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.nameLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - lazy
- (UILabel *)nameLabel {
    if (!_nameLabel) {
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.numberOfLines = 0;
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 1. 定义文案内容
        NSString *title = @"兼容性提示\n";
        NSString *reason = @"由于您的设备系统低于 iOS 14 且搭载 A12+ 处理器，受系统架构限制，以下功能暂不可用：\n";
        NSString *features = @"• 控制中心增强\n• 应用清理\n• 录制+回放功能\n• 应用管理部分功能";
        
        NSString *fullText = [NSString stringWithFormat:@"%@%@%@", title, reason, features];
        
        // 2. 创建富文本
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:fullText];
        
        // --- 样式设置 ---
        
        // 全体行间距
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 6; // 行间距
        paragraphStyle.paragraphSpacing = 8; // 段落间距
        [attrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, fullText.length)];
        
        // 标题样式：红色、加粗、大字号
        NSRange titleRange = [fullText rangeOfString:title];
        [attrStr addAttributes:@{
            NSForegroundColorAttributeName: [UIColor systemRedColor],
            NSFontAttributeName: [UIFont boldSystemFontOfSize:20]
        } range:titleRange];
        
        // 原因样式：深灰色、普通字号
        NSRange reasonRange = [fullText rangeOfString:reason];
        [attrStr addAttributes:@{
            NSForegroundColorAttributeName: [UIColor darkGrayColor],
            NSFontAttributeName: [UIFont systemFontOfSize:15]
        } range:reasonRange];
        
        // 功能列表样式：黑色、中等字号、稍粗
        NSRange featuresRange = [fullText rangeOfString:features];
        [attrStr addAttributes:@{
            NSForegroundColorAttributeName: [UIColor blackColor],
            NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]
        } range:featuresRange];
        
        _nameLabel.attributedText = attrStr;
    }
    return _nameLabel;
}
@end

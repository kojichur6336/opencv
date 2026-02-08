//
//  YKDeviceCell.h
//  YKApp
//
//  Created by liuxiaobin on 2026/1/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK - 设备Cell
@interface YKDeviceCell : UITableViewCell
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *valueLabel;
@property(nonatomic, strong) UILabel *tipLabel;
@end

NS_ASSUME_NONNULL_END

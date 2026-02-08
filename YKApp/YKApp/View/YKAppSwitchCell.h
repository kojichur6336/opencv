//
//  YKAppSwitchCell.h
//  YKApp
//
//  Created by liuxiaobin on 2025/12/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YKAppSwitchCell;
@protocol YKAppSwitchCellDelegate <NSObject>


/// 开关单元格状态变更的回调
/// - Parameters:
///   - cell: 触发事件的 Cell 对象 (YKAppSwitchCell)
///   - name: 该开关对应的名称或标识符
///   - status: 变更后的最新状态 (YES 为开启，NO 为关闭)
-(void)appSwitchCell:(YKAppSwitchCell *)cell name:(NSString *)name didChangeStatus:(BOOL)status;

@end



/// MARK - 开关Cell
@interface YKAppSwitchCell : UITableViewCell
@property(nonatomic, weak) id<YKAppSwitchCellDelegate> delegate;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UISwitch *switchView;
@end

NS_ASSUME_NONNULL_END

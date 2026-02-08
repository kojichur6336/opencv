//
//  YKHeaderView.h
//  YKApp
//
//  Created by liuxiaobin on 2025/10/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YKHeaderView;
@protocol YKHeaderViewDelegate <NSObject>


/// 后退回调
/// - Parameters:
///   - view: 视图
///   - backButton: 后退按钮
-(void)ykHeaderView:(YKHeaderView *)view backButton:(UIControl *)backButton;

@end

/// MARK - 通用头部视图
@interface YKHeaderView : UIView
@property(nonatomic, strong) UILabel *titleLabel;//标题标签
@property(nonatomic, weak) id<YKHeaderViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

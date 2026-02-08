//
//  YKNavigationView.h
//  Created on 2025/10/10
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YKNavigationView;
@protocol YKNavigationViewDelegate <NSObject>


/// 点击首页
/// - Parameters:
///   - view: YKNavigationView
///   - home: 首页
-(void)ykNavigationView:(YKNavigationView *)view home:(UIControl *)home;



/// 点击二维码
/// - Parameters:
///   - view: YKNavigationView
///   - qrcode: 二维码
-(void)ykNavigationView:(YKNavigationView *)view qrcode:(UIControl *)qrcode;


/// 点击了日志按钮
/// - Parameters:
///   - view: YKNavigationView
///   - log: 日志
-(void)ykNavigationView:(YKNavigationView *)view log:(UIControl *)log;
@end

/// MARK - 头部视图
@interface YKHomeNavigationView : UIView
@property(nonatomic, weak) id<YKNavigationViewDelegate> delegate;//委托
@end

NS_ASSUME_NONNULL_END

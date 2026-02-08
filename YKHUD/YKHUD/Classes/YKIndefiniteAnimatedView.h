//
//  YKIndefiniteAnimatedView.h
//  Created on 2023/8/21
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - IndefiniteAnimatedView
@interface YKIndefiniteAnimatedView : UIView

@property (nonatomic, assign) CGFloat strokeThickness;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIColor *strokeColor;
@end

NS_ASSUME_NONNULL_END

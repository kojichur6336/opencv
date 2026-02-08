//
//  YKProgressAnimatedView.h
//  Created on 2023/8/21
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 进度动画视图
@interface YKProgressAnimatedView : UIView

@property (nonatomic, assign) CGFloat radius; //半径
@property (nonatomic, assign) CGFloat strokeThickness;//条纹的厚度
@property (nonatomic, strong) UIColor *strokeColor;//条纹颜色
@property (nonatomic, assign) CGFloat strokeEnd;//行程结束
@end

NS_ASSUME_NONNULL_END

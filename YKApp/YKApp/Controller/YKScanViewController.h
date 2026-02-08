//
//  YKScanViewController.h
//  YKApp
//
//  Created by liuxiaobin on 2025/10/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define YKScanViewController                 A27d223630802dc96856d94d00c5ce60del

@class YKScanViewController;
@protocol YKScanViewControllerDelegate <NSObject>

-(void)ykScanViewController:(YKScanViewController *)vc qrcode:(NSString *)qrcode;

@end

/// MARK - 扫一扫
@interface YKScanViewController : UIViewController
@property(nonatomic, weak) id<YKScanViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

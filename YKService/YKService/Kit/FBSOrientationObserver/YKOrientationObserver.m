//
//  YKOrientationObserver.m
//  YKService
//
//  Created by liuxiaobin on 2025/12/4.
//

#import <dlfcn.h>
#import <objc/runtime.h>
#import "YKServiceTool.h"
#import "YKServiceLogger.h"
#import "YKOrientationObserver.h"

@interface FBSOrientationUpdate : NSObject
- (NSUInteger)sequenceNumber;
- (NSInteger)rotationDirection;
- (UIInterfaceOrientation)orientation;
- (NSTimeInterval)duration;
@end

@interface FBSOrientationObserver : NSObject
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (void)activeInterfaceOrientationWithCompletion:(id)arg1;
- (void)invalidate;
- (void)setHandler:(void (^)(FBSOrientationUpdate *))handler;
- (void (^)(FBSOrientationUpdate *))handler;
@end


#define ykob_loadFrontBoardServices                 A3b1126c4f0bd9195939d71be3ebac5a3f5
#define ykob_frontBoardInstance                     B8f5cb62x077f3173c9ebde37432260edf5

@interface YKOrientationObserver()
@property(nonatomic, weak) id<YKOrientationObserverDelegate> delegate;
@property(nonatomic, strong) FBSOrientationObserver * ykob_frontBoardInstance;
@end

@implementation YKOrientationObserver

-(instancetype)initWithDelegate:(id<YKOrientationObserverDelegate>)delegate {
    self = [super init];
    if(self) {
        _delegate = delegate;
        [self ykob_loadFrontBoardServices];
    }
    return self;
}


#pragma mark - 加载前台服务类
-(void)ykob_loadFrontBoardServices {
    
    const char *library_path = @"/System/Library/PrivateFrameworks/FrontBoardServices.framework/FrontBoardServices".UTF8String;
    
    // 动态加载所选路径的库
    void *substrate = dlopen(library_path, RTLD_NOW);
    if (!substrate) {
        LOGI(@"加载FrontBoardServices失败: %s", dlerror());
        return;
    } else {
        
        Class frontBoardClass = objc_getClass("FBSOrientationObserver");
        __weak typeof(self) weakSelf = self;
        void (^handler)(FBSOrientationUpdate *) = ^(FBSOrientationUpdate *update) {
            if (!update)
                return;
            
            // 从 update 中获取最新的界面方向（UIInterfaceOrientation）
            UIInterfaceOrientation activeOrientation = [update orientation];
            
            // 以下是 debug 打印：序列号、旋转方向、方向值、动画时长
            //LOGI(@"方向发生变化: seq=%lu dir=%ld ori=%ld dur=%.3f",[update sequenceNumber], [update rotationDirection], (long)activeOrientation, [update duration]);
            [weakSelf.delegate didChangeOrientation:activeOrientation];
        };
        
        
        if (frontBoardClass) {
            
            self.ykob_frontBoardInstance = [[frontBoardClass alloc] init];
            if (self.ykob_frontBoardInstance) {
                [self.ykob_frontBoardInstance setHandler:handler];
            }
        }
    }
}
@end

//
//  YKSBToast.m
//  YKSBTweak
//
//  Created by liuxiaobin on 2025/9/17.
//

#import "YKSBToast.h"

@interface YKSBToastWindow : UIWindow
@property(nonatomic, strong) UILabel *titleLabel;//标题标签
@property(nonatomic, assign) CGFloat bottomSafeAreaHeight;//距于Y
@property(nonatomic, assign) CGPoint position;//位置
@property(nonatomic, assign) UIInterfaceOrientation orientation;//屏幕旋转状态
@property(nonatomic, assign) int minimumDismissTimeInterval; // 最小消失时间(默认2秒)
@property(nonatomic, assign) int maximumDismissTimeInterval; // 最大消失时间间隔(默认CGFLOAT_MAX)


/// 隐藏
-(void)hideToast;
@end

@implementation YKSBToastWindow

+ (instancetype)sharedInstance
{
    static YKSBToastWindow *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[YKSBToastWindow alloc] initWithFrame:CGRectZero];
    });
    return sharedInstance;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        [self config];
    }
    return self;
}

#pragma mark - 配置
-(void)config {
    
    _orientation = UIInterfaceOrientationPortrait;
    self.windowLevel = UIWindowLevelAlert + 1000;
    self.userInteractionEnabled = NO;
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 4.0f;
    self.backgroundColor = [UIColor darkGrayColor];
    [self setHidden:YES];
    self.minimumDismissTimeInterval = 2;
    self.maximumDismissTimeInterval = CGFLOAT_MAX;
    
    UIWindowScene *mainScene = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes)
    {
        if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive)
        {
            mainScene = scene;
            break;
        }
    }
    
    _bottomSafeAreaHeight = 40;
    [self addSubview:self.titleLabel];
    self.windowScene = mainScene;
    [self makeKeyAndVisible];
}


#pragma mark - 显示消息
-(void)showMessage:(NSString *)message point:(CGPoint)position
{
    
    _position = position;
    if (!(_position.x == -1 && _position.y == -1)) {
        CGFloat scale = [UIScreen mainScreen].scale;
        _position = CGPointMake(_position.x / scale, _position.y / scale);
    }
    
    CGSize size = UIScreen.mainScreen.bounds.size;
    
    //屏幕左右的间距设置为20
    CGFloat maxWidth = size.width - 2 * 20;
    
    // 定义你的字体
    UIFont *font = [UIFont systemFontOfSize:12];

    // 定义文本属性
    NSDictionary *attributes = @{NSFontAttributeName: font};

    // 计算文本的尺寸
    CGSize maxSize = CGSizeZero;
    if (size.width > size.height)
    {
        maxSize = CGSizeMake(maxWidth, size.height);
    } else {
        maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    }
    CGRect textRect = [message boundingRectWithSize:maxSize
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:attributes
                                             context:nil];
    // 获取文本尺寸
    CGSize msgtxtSize = textRect.size;
    CGFloat w = msgtxtSize.width + 10;
    CGFloat h = msgtxtSize.height + 10;
     
    self.transform = CGAffineTransformIdentity;
    self.frame = CGRectMake(0, 0, w, h);
    
    _titleLabel.frame = CGRectMake(0, 0, msgtxtSize.width, msgtxtSize.height);
    _titleLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _titleLabel.text = message;
    [self setupPositionWithOrientation];
    
    self.hidden = false;
}

#pragma mark - 设置
-(void)setupPositionWithOrientation
{
    CGSize size = UIScreen.mainScreen.bounds.size;
    CGFloat screenWidth = size.width < size.height ? size.width : size.height;
    CGFloat screenHeight = size.width < size.height ? size.height : size.width;
    CGFloat toastWidth = self.frame.size.width;
    CGFloat toastHeight = self.frame.size.height;
    CGFloat halfScreenWidth = screenWidth * 0.5f;
    CGFloat halfScreenHeight = screenHeight * 0.5f;
    CGFloat halfToastWidth = toastWidth * 0.5f;
    CGFloat halfToastHeight = toastHeight * 0.5f;
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    CGAffineTransform transform;
    switch (_orientation)
    {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait: {
            transform = CGAffineTransformMakeRotation(M_PI*0.0f);
            x = _position.x==-1?halfScreenWidth:MIN(screenWidth-halfToastWidth,MAX(halfToastWidth,_position.x+halfToastWidth));
            y = _position.y==-1?screenHeight-_bottomSafeAreaHeight-halfToastHeight:MIN(screenHeight-halfToastHeight,MAX(halfToastHeight,_position.y+halfToastHeight));
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            transform = CGAffineTransformMakeRotation(M_PI*1.0f);
            x = _position.x==-1?halfScreenWidth:MIN(screenWidth-halfToastWidth,MAX(halfToastWidth,screenWidth-_position.x-halfToastWidth));
            y = _position.y==-1?_bottomSafeAreaHeight+halfToastHeight:MIN(screenHeight-halfToastHeight,MAX(screenHeight-_position.y-halfToastHeight,halfToastHeight));
            break;
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            transform = CGAffineTransformMakeRotation(M_PI*1.5f);
            x = _position.x==-1?screenWidth-_bottomSafeAreaHeight-halfToastHeight:MIN(screenWidth-halfToastHeight,MAX(halfToastHeight,_position.y+halfToastHeight));
            y = _position.y==-1?halfScreenHeight:MIN(screenHeight-halfToastWidth,MAX(halfToastWidth,screenHeight-_position.x-halfToastWidth));
            break;
        }
           
        case UIInterfaceOrientationLandscapeRight: {
            transform = CGAffineTransformMakeRotation(M_PI*0.5f);
            x = _position.x==-1?_bottomSafeAreaHeight+halfToastHeight:MIN(screenWidth-halfToastHeight,MAX(halfToastHeight,screenWidth-_position.y-halfToastHeight));
            y = _position.y==-1?halfScreenHeight:MIN(screenHeight-halfToastWidth,MAX(halfToastWidth,_position.x+halfToastWidth));
            break;
        }
    }
    
    self.transform = transform;
    self.center = CGPointMake(x, y);
}

#pragma mark - 隐藏
-(void)hideToast {
   self.hidden = true;
}

#pragma mark - 屏幕旋转
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    _orientation = toInterfaceOrientation;
    [UIView animateWithDuration:0.2 animations:^{
        [self setupPositionWithOrientation];
    }];
}


#pragma mark - lazy
-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = UIColor.clearColor;
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font = [UIFont systemFontOfSize:12];
    }
    return _titleLabel;
}


@end


@implementation YKSBToast

#pragma mark - 显示消息
+(void)showMessage:(NSString *)message {
    [self showMessage:message point:CGPointMake(-1, -1) duration:[self displayDurationForString:message]];
}


#pragma mark - 显示消息带持续时间
+(void)showMessage:(NSString *)message point:(CGPoint)position duration:(int)duration {
    
    [[YKSBToastWindow sharedInstance] showMessage:message point:position];
    [NSObject cancelPreviousPerformRequestsWithTarget:[YKSBToastWindow sharedInstance] selector:@selector(hideToast) object:nil];
    [[YKSBToastWindow sharedInstance] performSelector:@selector(hideToast) withObject:nil afterDelay:duration];
}

#pragma mark - 旋转
+(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    [[YKSBToastWindow sharedInstance] willRotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - 动态计算显示时长
+(int)displayDurationForString:(NSString*)string
{
    CGFloat minimum = MAX((CGFloat)string.length * 0.06 + 0.5, [YKSBToastWindow sharedInstance].minimumDismissTimeInterval);
    return MIN(minimum, [YKSBToastWindow sharedInstance].maximumDismissTimeInterval);
}
@end


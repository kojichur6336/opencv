//
//  YKAppController.m
//  YKApp
//
//  Created by liuxiaobin on 2025/9/14.
//

#import "YKToast.h"
#import "YKAppLogger.h"
#import "YKDeviceCell.h"
#import "YKDeviceModel.h"
#import "YKWarningCell.h"
#import "YKAppController.h"
#import "YKAppSwitchCell.h"
#import "YKAppKeyValueCell.h"
#import "YKAppIPCController.h"
#import "YKLogViewController.h"
#import "YKHomeNavigationView.h"
#import "YKScanViewController.h"
#import "YKAppContentArrowsCell.h"
#import "YKHomeHeaderFooterView.h"

#define yk_configView                    Ad5212b2c2cc3f423c21cbf5122fbb7109f
#define yk_configLocation                B13048a892xb1ccce878f2d867b0a551254

// --- 颜色配置 (升级为更高级的配色) ---
// 背景色：深邃的黑蓝
#define kBgTopColor     [UIColor colorWithRed:10/255.0 green:12/255.0 blue:20/255.0 alpha:1.0]
#define kBgBottomColor  [UIColor colorWithRed:0/255.0 green:0/255.0 blue:5/255.0 alpha:1.0]

// 卡片颜色：实色深灰 (比背景稍亮，确保可读性)
#define kCardColor      [UIColor colorWithRed:35/255.0 green:37/255.0 blue:45/255.0 alpha:1.0]

// 文字颜色
#define kTitleColor     [UIColor colorWithWhite:0.6 alpha:1.0] // 标题灰色
#define kValueColor     [UIColor whiteColor]                   // 内容纯白
#define kAccentColor    [UIColor colorWithRed:64/255.0 green:156/255.0 blue:255/255.0 alpha:1.0] // 科技蓝
#define kSuccessColor   [UIColor colorWithRed:46/255.0 green:204/255.0 blue:113/255.0 alpha:1.0] // 状态绿

@interface YKAppController ()<UITableViewDataSource, UITableViewDelegate, YKNavigationViewDelegate, YKAppIPCControllerDelegate, YKScanViewControllerDelegate, YKAppSwitchCellDelegate>
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;//加载视图
@property(nonatomic, strong) YKHomeNavigationView *navigationView;//导航视图
@property(nonatomic, strong) UITableView *tableView;//列表
@property(nonatomic, strong) NSMutableArray *sections;//分组
@property(nonatomic, strong) UITextView *logTextView; // 用于显示读取到的文件内容
@property(nonatomic, strong) YKAppIPCController* iPCController;//进程通讯控制器
@property(nonatomic, strong) CAGradientLayer *backgroundGradientLayer; // 背景渐变
@end

@implementation YKAppController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置高级感背景
    [self setupPremiumBackground];
    
    self.sections = [[NSMutableArray alloc] init];
    [self yk_configView];
    [self yk_configLocation];
    
    [self.activityIndicatorView startAnimating];
    [self.iPCController yk_getDeviceInfo];
}

// 优化背景：更加深邃沉稳
- (void)setupPremiumBackground {
    self.view.backgroundColor = kBgTopColor;
    
    if (!self.backgroundGradientLayer) {
        self.backgroundGradientLayer = [CAGradientLayer layer];
        self.backgroundGradientLayer.frame = self.view.bounds;
        self.backgroundGradientLayer.colors = @[
            (__bridge id)kBgTopColor.CGColor,
            (__bridge id)kBgBottomColor.CGColor
        ];
        self.backgroundGradientLayer.startPoint = CGPointMake(0, 0);
        self.backgroundGradientLayer.endPoint = CGPointMake(0, 1); // 垂直渐变，更稳重
        [self.view.layer insertSublayer:self.backgroundGradientLayer atIndex:0];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundGradientLayer.frame = self.view.bounds;
}

#pragma mark - 配置视图
-(void)yk_configView {
    
    [self.view addSubview:self.navigationView];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.logTextView];
    [self.view addSubview:self.activityIndicatorView];
}

#pragma mark - 配置位置
-(void)yk_configLocation {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [NSLayoutConstraint activateConstraints:@[
        
        [self.navigationView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.navigationView.heightAnchor constraintEqualToConstant:44 + UIApplication.sharedApplication.statusBarFrame.size.height],
        [self.navigationView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        
        
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor: self.navigationView.bottomAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        
        [self.logTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.logTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.logTextView.topAnchor constraintEqualToAnchor: self.navigationView.bottomAnchor],
        [self.logTextView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        
        [self.activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        
    ]];
#pragma clang diagnostic pop
}


#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSDictionary *sectionInfo = self.sections[section];
    NSArray *items = sectionInfo[@"items"];
    return items.count;
    
}

// 核心优化：让卡片更立体，颜色更现代
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 1. 卡片改为实色背景，避免半透明导致的"浑浊感"
    cell.backgroundColor = kCardColor;
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    // 2. 无点击高亮
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 3. 字体优化：左侧小而灰，右侧大而亮
    cell.textLabel.textColor = kTitleColor;
    cell.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular]; // 稍微改小一点，显得精致
    
    cell.detailTextLabel.textColor = kValueColor;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    
    // 尝试自定义 Cell 内部的 Label 样式
    if ([cell respondsToSelector:@selector(nameLabel)]) {
        UILabel *label = [cell valueForKey:@"nameLabel"];
        label.textColor = kTitleColor;
        label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular]; // 左侧：常规字体，灰色
    }
    if ([cell respondsToSelector:@selector(valueLabel)]) {
        UILabel *label = [cell valueForKey:@"valueLabel"];
        label.textColor = kValueColor; // 默认右侧白色
        label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold]; // 右侧：加粗，白色，突出重点
        
        // 特殊状态颜色处理
        NSString *text = label.text;
        if ([text containsString:@"已连接"] || [text containsString:@"开启"]) {
            label.textColor = kSuccessColor; // 绿色表示状态好
        } else if ([text containsString:@"WIFI"] || [text containsString:@"IP"]) {
            label.textColor = kAccentColor; // 蓝色表示关键信息
        }
    }
    
    // 4. 圆角优化：iOS 风格圆角
    cell.layer.cornerRadius = 10.0;
    cell.layer.masksToBounds = YES;
    cell.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.05].CGColor; // 极淡的边框，增加精致感
    cell.layer.borderWidth = 0.5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *sectionInfo = self.sections[indexPath.section];
    NSArray *items = sectionInfo[@"items"];
    NSDictionary *itemInfo = items[indexPath.row];
    NSString *cellType = itemInfo[@"cellType"];
    
    UITableViewCell *baseCell = nil;
    
    if ([cellType isEqualToString:@"YKDeviceCell"]) {
        YKDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKDeviceCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        baseCell = cell;
    } else if ([cellType isEqualToString:@"YKAppKeyValueCell"]) {
        
        YKAppKeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppKeyValueCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        baseCell = cell;
    } else if ([cellType isEqualToString:@"YKAppContentArrowsCell"]) {
        YKAppContentArrowsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppContentArrowsCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        // 箭头或者可点击项，右侧文字稍微变灰一点表示不是重点数据
        cell.valueLabel.textColor = [UIColor lightGrayColor];
        baseCell = cell;
    } else if ([cellType isEqualToString:@"YKAppSwitchCell"]) {
        YKAppSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppSwitchCell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.nameLabel.text = itemInfo[@"key"];
        cell.switchView.on = [itemInfo[@"value"] intValue];
        // 调整 Switch 颜色
        cell.switchView.onTintColor = kSuccessColor; // 开关绿色，符合直觉
        baseCell = cell;
    } else if ([cellType isEqualToString:@"YKWarningCell"]) {
        
        YKWarningCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKWarningCell" forIndexPath:indexPath];
        // 警告 Cell 特殊处理
        cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.15]; // 淡红色背景
        baseCell = cell;
    }
    
    return baseCell ? baseCell : [[UITableViewCell alloc] init];
}

#pragma mark - UITableViewDelegate
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    YKHomeHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"YKHomeHeaderFooterView"];
    NSDictionary *sectionInfo = self.sections[section];
    header.titleLabel.text = sectionInfo[@"title"];
    // Header 样式优化：更大气
    header.contentView.backgroundColor = [UIColor clearColor];
    header.titleLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0]; // 标题亮白
    header.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold]; // 加大加粗
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60.0; // 增加间距
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *sectionInfo = self.sections[indexPath.section];
    NSArray *items = sectionInfo[@"items"];
    NSDictionary *itemInfo = items[indexPath.row];
    
    if ([itemInfo[@"key"] isKindOfClass:[NSString class]] && [itemInfo[@"key"] isEqualToString:@"重启服务"]) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定重启服务?"
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleAlert];
        // 强制 Alert 暗黑模式
        alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
            [self.iPCController yk_reStart];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        [alert addAction:confirm];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - YKNavigationViewDelegate
-(void)ykNavigationView:(YKNavigationView *)view home:(UIControl *)home {
    [self.iPCController yk_homeScreen];
}

-(void)ykNavigationView:(YKNavigationView *)view qrcode:(UIControl *)qrcode {
    
    YKScanViewController *vc = [[YKScanViewController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)ykNavigationView:(YKNavigationView *)view log:(UIControl *)log {
#if YKLogMode != 0
    YKLogViewController *vc = [[YKLogViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
#endif
}

#pragma mark - YKScanViewControllerDelegate
-(void)ykScanViewController:(YKScanViewController *)vc qrcode:(NSString *)qrcode {
    
    [YKToast showWithStatus:@"连接中..."];
    [self.iPCController yk_scanQrcode:qrcode];
}

#pragma mark - YKAppIPCControllerDelegate
-(void)appIPCController:(YKAppIPCController *)controller deviceInfo:(NSDictionary *)deviceInfo {
    
    BOOL isChoicy = [deviceInfo[@"choicy"] boolValue];
    if (isChoicy)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:deviceInfo[@"choicyMsg"]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定"
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
                [self.iPCController yk_openSetting];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                               message:deviceInfo[@"springboardMsg"]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                
                UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定重启"
                                                                  style:UIAlertActionStyleDestructive
                                                                handler:^(UIAlertAction * _Nonnull action) {
                    [self.iPCController yk_reStart];
                }];
                
                [alert addAction:confirm];
                [self presentViewController:alert animated:YES completion:nil];
            }];
            
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
    
    BOOL supportsThisDevice = [deviceInfo[@"supportsThisDevice"] boolValue];
    BOOL isSB = [deviceInfo[@"isSpringboardRestartRequired"] boolValue];
    [self.sections removeAllObjects];
    if (isSB && supportsThisDevice) {
        //如果SB没有重启，或者没被注入的话，就需要重启下SpringBoard
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:deviceInfo[@"springboardMsg"]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定重启"
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
                [self.iPCController yk_reStart];
            }];
            
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    
    NSArray *connected = deviceInfo[@"connectedServices"];
    NSMutableArray *temConnected = [[NSMutableArray alloc] init];
    [temConnected addObject:@{@"cellType": @"YKAppSwitchCell", @"key": @"服务开关", @"value": deviceInfo[@"isServiceEnabled"]}];
    if (connected.count == 0) {
        [temConnected addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备", @"value": @"未连接"}];
    } else {
        
        for (NSDictionary *item in connected) {
            
            NSString *remoteDeviceName = item[@"remoteDeviceName"];
            NSString *ip = item[@"ip"];
            
            NSString *value;
            if ([ip isEqualToString:@"127.0.0.1"]) {
                value = @"USB连接";
            } else {
                value = [NSString stringWithFormat:@"WIFI (%@)", ip];
            }
            
            [temConnected addObject:@{
                @"cellType": @"YKDeviceCell",
                @"key": remoteDeviceName,
                @"value": value
            }];
        }
    }
    
    [self.sections addObject:@{@"title": @"连接设备", @"items":temConnected}];
    
    
    NSString *environment = deviceInfo[@"environment"];
    NSMutableArray *infoArray = [[NSMutableArray alloc] init];
    NSString *deviceName = deviceInfo[@"deviceName"];
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备名称", @"value": deviceName}];
    
    NSString *deviceIP = deviceInfo[@"ip"];
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"本地 IP", @"value": deviceIP}];
    
    NSString *deviceID = deviceInfo[@"deviceID"];
    if (deviceID.length > 0) {
        [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备 ID", @"value": deviceID}];
    } else {
        [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备 ID", @"value": deviceID}];
    }
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"越狱环境", @"value": environment}];
    [self.sections addObject:@{@"title": @"设备信息", @"items":infoArray}];
    
    
    NSMutableArray *otherArray = [[NSMutableArray alloc] init];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [otherArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"当前版本", @"value": appVersion}];
    [otherArray addObject:@{@"cellType": @"YKAppContentArrowsCell", @"key": @"重启服务", @"value": @""}];
    [self.sections addObject:@{@"title": @"其他设置", @"items":otherArray}];
    
    
    // 判断该设备型号支持不支持
    if (!supportsThisDevice) {
        NSMutableArray *warningArray = [[NSMutableArray alloc] init];
        [warningArray addObject:@{@"cellType": @"YKWarningCell", @"key": @"", @"value": @""}];
        [self.sections addObject:@{@"title": @"提示", @"items":warningArray}];
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView reloadData];
        self.tableView.hidden = false;
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView.hidden = YES;
    });
}

#pragma mark - 链接错误
-(void)appIPCController:(YKAppIPCController *)controller qrcodeMsg:(NSString *)msg
{
    [YKToast dismiss];
    if (msg.length > 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:msg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定"
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
            }];
            
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

#pragma mark - 回调
-(void)appIPCController:(YKAppIPCController *)controller firstTxtFileName:(NSString *)firstTxtFileName errorMsg:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView.hidden = YES;
        // 2. 显示 TextView
        self.logTextView.hidden = NO;
        [self.view bringSubviewToFront:self.logTextView];
        
        // 3. 构造富文本（包含标题和正文）- 样式调整为极客风格
        NSMutableAttributedString *attriString = [[NSMutableAttributedString alloc] init];
        
        // --- 设置标题 ---
        NSString *title = @"> LOG OUTPUT...\n";
        NSDictionary *titleAttr = @{
            NSFontAttributeName: [UIFont fontWithName:@"Menlo-Bold" size:14.0f] ?: [UIFont boldSystemFontOfSize:14],
            NSForegroundColorAttributeName: [UIColor lightGrayColor]
        };
        [attriString appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        
        // --- 添加一条分割线 ---
        NSString *line = @"> ---------------------------------\n\n";
        NSDictionary *lineAttr = @{
            NSFontAttributeName: [UIFont fontWithName:@"Menlo-Regular" size:12.0f] ?: [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName: [UIColor darkGrayColor]
        };
        [attriString appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:lineAttr]];
        
        // --- 设置正文内容 ---
        // 如果有错误信息则显示错误，否则显示传回的内容
        NSString *contentText = (msg && msg.length > 0) ? [NSString stringWithFormat:@"> Error: %@", msg] : (firstTxtFileName ?: @"> No content.");
        
        NSDictionary *contentAttr = @{
            NSFontAttributeName: [UIFont fontWithName:@"Menlo-Regular" size:12.0f] ?: [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName: kValueColor // 使用白色作为日志内容
        };
        [attriString appendAttributedString:[[NSAttributedString alloc] initWithString:contentText attributes:contentAttr]];
        
        // 4. 赋值并重置滚动位置
        self.logTextView.attributedText = attriString;
    });
    
}

#pragma mark - YKAppSwitchCellDelegate
-(void)appSwitchCell:(YKAppSwitchCell *)cell name:(NSString *)name didChangeStatus:(BOOL)status {
    
    [self.iPCController yk_isServiceEnabled:status];
}



#pragma mark - lazy
-(YKAppIPCController *)iPCController {
    
    if (!_iPCController) {
        _iPCController = [[YKAppIPCController alloc] init];
        _iPCController.delegate = self;
    }
    return _iPCController;
}

-(YKHomeNavigationView *)navigationView {
    
    if (!_navigationView) {
        _navigationView = [[YKHomeNavigationView alloc] init];
        _navigationView.delegate = self;
        _navigationView.translatesAutoresizingMaskIntoConstraints = false;
        // 导航栏透明
        _navigationView.backgroundColor = [UIColor clearColor];
    }
    return _navigationView;
}

-(UIActivityIndicatorView *)activityIndicatorView {
    
    if (!_activityIndicatorView) {
        // 大号白色加载菊花
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        _activityIndicatorView.color = [UIColor whiteColor]; // 纯白，不搞花哨的
        _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _activityIndicatorView;
}

-(UITableView *)tableView {
    
    if (!_tableView) {
        // 保持 Grouped 样式，但背景色由 ViewController 统一管理
        _tableView = [[UITableView alloc] initWithFrame:(CGRect){0, 0, 0, 0} style:UITableViewStyleInsetGrouped];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 60;
        _tableView.backgroundColor = [UIColor clearColor]; // 透明背景
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 移除默认分割线
        _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite; // 滚动条白色
        _tableView.contentInset = UIEdgeInsetsMake(10, 0, 20, 0); // 增加顶部底部间距
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.hidden = YES;
        [_tableView registerClass:[YKDeviceCell class] forCellReuseIdentifier:@"YKDeviceCell"];
        [_tableView registerClass:[YKAppContentArrowsCell class] forCellReuseIdentifier:@"YKAppContentArrowsCell"];
        [_tableView registerClass:[YKAppKeyValueCell class] forCellReuseIdentifier:@"YKAppKeyValueCell"];
        [_tableView registerClass:[YKAppSwitchCell class] forCellReuseIdentifier:@"YKAppSwitchCell"];
        [_tableView registerClass:[YKWarningCell class] forCellReuseIdentifier:@"YKWarningCell"];
        [_tableView registerClass:[YKHomeHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"YKHomeHeaderFooterView"];
        
        
        _tableView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _tableView;
}

-(UITextView *)logTextView {
    if (!_logTextView) {
        
        _logTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
        // 终端样式背景，深黑
        _logTextView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.1 alpha:0.95];
        // 终端样式字体
        _logTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:12.0f];
        _logTextView.textColor = [UIColor whiteColor];
        _logTextView.editable = NO;
        _logTextView.selectable = YES;
        _logTextView.scrollEnabled = YES;
        _logTextView.userInteractionEnabled = YES;
        _logTextView.textContainerInset = UIEdgeInsetsMake(20, 15, 20, 15); // 增加内边距
        _logTextView.hidden = YES;
        
        _logTextView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _logTextView;
}
@end
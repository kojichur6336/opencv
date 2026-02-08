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



@interface YKAppController ()<UITableViewDataSource, UITableViewDelegate, YKNavigationViewDelegate, YKAppIPCControllerDelegate, YKScanViewControllerDelegate, YKAppSwitchCellDelegate>
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;//加载视图
@property(nonatomic, strong) YKHomeNavigationView *navigationView;//导航视图
@property(nonatomic, strong) UITableView *tableView;//列表
@property(nonatomic, strong) NSMutableArray *sections;//分组
@property(nonatomic, strong) UITextView *logTextView; // 用于显示读取到的文件内容
@property(nonatomic, strong) YKAppIPCController* iPCController;//进程通讯控制器
@end

@implementation YKAppController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.sections = [[NSMutableArray alloc] init];
    [self yk_configView];
    [self yk_configLocation];
    
    [self.activityIndicatorView startAnimating];
    [self.iPCController yk_getDeviceInfo];
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
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *sectionInfo = self.sections[indexPath.section];
    NSArray *items = sectionInfo[@"items"];
    NSDictionary *itemInfo = items[indexPath.row];
    NSString *cellType = itemInfo[@"cellType"];
    
    if ([cellType isEqualToString:@"YKDeviceCell"]) {
        YKDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKDeviceCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        return cell;
    } else if ([cellType isEqualToString:@"YKAppKeyValueCell"]) {
        
        YKAppKeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppKeyValueCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        return cell;
    } else if ([cellType isEqualToString:@"YKAppContentArrowsCell"]) {
        YKAppContentArrowsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppContentArrowsCell" forIndexPath:indexPath];
        cell.nameLabel.text = itemInfo[@"key"];
        cell.valueLabel.text = itemInfo[@"value"];
        return cell;
    } else if ([cellType isEqualToString:@"YKAppSwitchCell"]) {
        YKAppSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKAppSwitchCell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.nameLabel.text = itemInfo[@"key"];
        cell.switchView.on = [itemInfo[@"value"] intValue];
        return cell;
    } else if ([cellType isEqualToString:@"YKWarningCell"]) {
        
        YKWarningCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKWarningCell" forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    YKHomeHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"YKHomeHeaderFooterView"];
    NSDictionary *sectionInfo = self.sections[section];
    header.titleLabel.text = sectionInfo[@"title"];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *sectionInfo = self.sections[indexPath.section];
    NSArray *items = sectionInfo[@"items"];
    NSDictionary *itemInfo = items[indexPath.row];
    
    if ([itemInfo[@"key"] isKindOfClass:[NSString class]] && [itemInfo[@"key"] isEqualToString:@"重启服务"]) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定重启服务?"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
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
            
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定"
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
                [self.iPCController yk_openSetting];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                               message:deviceInfo[@"springboardMsg"]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
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
                value = [NSString stringWithFormat:@"WIFI连接(%@)", ip];
            }
            
            [temConnected addObject:@{
                @"cellType": @"YKDeviceCell",
                @"key": remoteDeviceName,
                @"value": value
            }];
        }
    }
    
    [self.sections addObject:@{@"title": @"📲连接设备", @"items":temConnected}];
    
    
    NSString *environment = deviceInfo[@"environment"];
    NSMutableArray *infoArray = [[NSMutableArray alloc] init];
    NSString *deviceName = deviceInfo[@"deviceName"];
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备名称", @"value": deviceName}];
    
    NSString *deviceIP = deviceInfo[@"ip"];
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"IP", @"value": deviceIP}];
    
    NSString *deviceID = deviceInfo[@"deviceID"];
    if (deviceID.length > 0) {
        [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备标识", @"value": deviceID}];
    } else {
        [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"设备标识", @"value": deviceID}];
    }
    [infoArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"越狱方式", @"value": environment}];
    [self.sections addObject:@{@"title": @"🆔设备信息", @"items":infoArray}];
    
    
    NSMutableArray *otherArray = [[NSMutableArray alloc] init];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [otherArray addObject:@{@"cellType": @"YKAppKeyValueCell", @"key": @"版本号", @"value": appVersion}];
    [otherArray addObject:@{@"cellType": @"YKAppContentArrowsCell", @"key": @"重启服务", @"value": @""}];
    [self.sections addObject:@{@"title": @"🧩其他", @"items":otherArray}];
    
    
    // 判断该设备型号支持不支持
    if (!supportsThisDevice) {
        NSMutableArray *warningArray = [[NSMutableArray alloc] init];
        [warningArray addObject:@{@"cellType": @"YKWarningCell", @"key": @"", @"value": @""}];
        [self.sections addObject:@{@"title": @"⚠️提示", @"items":warningArray}];
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
        
        // 3. 构造富文本（包含标题和正文）
        NSMutableAttributedString *attriString = [[NSMutableAttributedString alloc] init];
        
        // --- 设置标题 ---
        NSString *title = @"请截图发给客服，崩溃日志如下\n";
        NSDictionary *titleAttr = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
            NSForegroundColorAttributeName: [UIColor blackColor]
        };
        [attriString appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttr]];
        
        // --- 添加一条分割线 ---
        [attriString appendAttributedString:[[NSAttributedString alloc] initWithString:@"---------------------------------\n\n"]];
        
        // --- 设置正文内容 ---
        // 如果有错误信息则显示错误，否则显示传回的内容
        NSString *contentText = (msg && msg.length > 0) ? [NSString stringWithFormat:@"错误提示: %@", msg] : (firstTxtFileName ?: @"(内容为空)");
        
        NSDictionary *contentAttr = @{
            NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
            NSForegroundColorAttributeName: [UIColor darkGrayColor]
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
    }
    return _navigationView;
}

-(UIActivityIndicatorView *)activityIndicatorView {
    
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _activityIndicatorView.tintColor = UIColor.whiteColor;
        _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _activityIndicatorView;
}

-(UITableView *)tableView {
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:(CGRect){0, 0, 0, 0} style:UITableViewStyleInsetGrouped];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 60;
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
        _logTextView.backgroundColor = [UIColor whiteColor];
        _logTextView.font = [UIFont systemFontOfSize:14.0f];
        _logTextView.textColor = [UIColor blackColor];
        _logTextView.editable = NO;
        _logTextView.selectable = YES;
        _logTextView.scrollEnabled = YES;
        _logTextView.userInteractionEnabled = YES;
        _logTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _logTextView.hidden = YES;
        _logTextView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _logTextView;
}
@end

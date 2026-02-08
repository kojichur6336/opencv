//
//  YKLogViewController.m
//  Created on 2026/2/6
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2026 LMKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)   
//

#import "YKLogViewController.h"
#import "YKHeaderView.h"
#import "YKLogReaderManager.h"

@interface YKLogViewController () <YKHeaderViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong)YKHeaderView *headerView;
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<NSString *> *logData; // 日志数据源
@property(nonatomic, assign)BOOL isAutoScroll; // 是否允许自动滚动到底部
@end

@implementation YKLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logData = [NSMutableArray array];
    self.isAutoScroll = YES; // 初始状态开启自动滚动
    
    [self configView];
    [self configLocation];
    [self startLoggingService];
}

#pragma mark - 视图释放时停止监听，节省系统资源
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [[YKLogReaderManager sharedManager] stopMonitoring];
    }
}

#pragma mark - 配置视图
-(void)configView {
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.tableView];
}

#pragma mark - 配置位置
-(void)configLocation {
    [NSLayoutConstraint activateConstraints:@[
        // 头部视图
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:44 + UIApplication.sharedApplication.statusBarFrame.size.height],
        
        // 列表视图：位于头部下方，撑满屏幕
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - 核心业务逻辑
-(void)startLoggingService {
    __weak typeof(self) weakSelf = self;
    
    // 启动跨进程日志监听
    [[YKLogReaderManager sharedManager] startReadingTodayLogWithUpdate:^(NSString *newLog) {
        [weakSelf appendNewLogContent:newLog];
    }];
}

-(void)appendNewLogContent:(NSString *)content {
    
    if (!content || content.length == 0) return;

    // 1. 将读取到的块按行拆分
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // 2. 批量添加到数据源
    for (NSString *line in lines) {
        if (line.length > 0) {
            [self.logData addObject:line];
        }
    }

    // 3. 性能保护：超过 2000 行则移除旧日志，防止内存溢出
    if (self.logData.count > 2000) {
        [self.logData removeObjectsInRange:NSMakeRange(0, self.logData.count - 2000)];
    }

    // 4. 刷新界面
    [self.tableView reloadData];

    // 5. 智能滚动处理
    if (self.isAutoScroll && self.logData.count > 0) {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.logData.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - UITableView DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"YKLogCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        // 字体设置：使用等宽字体，显示日志更整齐
        cell.textLabel.font = [UIFont fontWithName:@"Courier" size:14.0f];
        cell.textLabel.numberOfLines = 0; //支持长日志换行
        cell.textLabel.textColor = [UIColor darkGrayColor];
    }
    
    if (indexPath.row < self.logData.count) {
        cell.textLabel.text = self.logData[indexPath.row];
    }
    return cell;
}

#pragma mark - 滚动控制逻辑 (手动翻阅时停止自动滚动)
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isAutoScroll = NO; // 用户开始手动滑动，停止自动追随
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateAutoScrollState:scrollView];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAutoScrollState:scrollView];
}

-(void)updateAutoScrollState:(UIScrollView *)scrollView {
    // 如果滑动到距离底部 50 像素以内，重新开启自动滚动
    CGFloat distanceFromBottom = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.frame.size.height);
    if (distanceFromBottom < 50) {
        self.isAutoScroll = YES;
    }
}

#pragma mark - YKHeaderViewDelegate
- (void)ykHeaderView:(YKHeaderView *)view backButton:(UIControl *)backButton {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Lazy Load
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        _tableView.estimatedRowHeight = 25.0;
        _tableView.rowHeight = UITableViewAutomaticDimension;
    }
    return _tableView;
}

- (YKHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[YKHeaderView alloc] init];
        _headerView.delegate = self;
        _headerView.titleLabel.text = @"系统日志";
        _headerView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return _headerView;
}

@end

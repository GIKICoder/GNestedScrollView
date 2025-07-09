//
//  GViewController.m
//  GStackScrollView
//
//  Created by GIKI on 08/05/2024.
//  Copyright (c) 2024 GIKI. All rights reserved.
//

#import "GViewController.h"
#import "ConfigItem.h"
#import "DouyinProfileViewController.h"
#import "DouyinMyProfileViewController.h"
@interface GViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<ConfigItem *> *configItems;

@end

@implementation GViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupConfigItems];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Home";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self.view addSubview:self.tableView];
}

- (void)setupConfigItems {
    __weak typeof(self) weakSelf = self;
    self.configItems = @[
        [[ConfigItem alloc] initWithTitle:@"Douyin-Other Profile" action:^{
            DouyinProfileViewController *vc = [DouyinProfileViewController new];
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }],
        [[ConfigItem alloc] initWithTitle:@"Douyin-My Profile" action:^{
            
            DouyinMyProfileViewController *vc = [DouyinMyProfileViewController new];
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }],
    ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.configItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    ConfigItem *item = self.configItems[indexPath.row];
    cell.textLabel.text = item.title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ConfigItem *item = self.configItems[indexPath.row];
    if (item.action) {
        item.action();
    }
}

@end

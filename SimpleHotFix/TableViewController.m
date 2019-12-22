//
//  TableViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "TableViewController.h"
#import "StingerViewController.h"
#import "AspectsViewController.h"
#import "MethodSwizzlingViewController.h"
#import "AOPViewController.h"

@interface TableViewController ()

@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = @[@"Method Swizzling", @"NSProxy", @"Aspects", @"Stinger", @"HotFix"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        MethodSwizzlingViewController *vc = [MethodSwizzlingViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 1) {
        AOPViewController *vc = [AOPViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 2) {
        AspectsViewController *vc = [AspectsViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 3) {
        StingerViewController *vc = [StingerViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 4) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        UIViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"viewcontroller"];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end

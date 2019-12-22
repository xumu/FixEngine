//
//  SubDemoViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/10/16.
//  Copyright © 2018 F_knight. All rights reserved.
//

#import "SubDemoViewController.h"

@interface SubDemoViewController ()

@end

@implementation SubDemoViewController

- (void)viewDidLoad {
//    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setupUI{
    [super setupUI];
    //Nothing to do
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    
    cell.textLabel.text = [@"subClass test ----- "stringByAppendingString:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
    
    return cell;
}

@end

//
//  StingerViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "StingerViewController.h"
#import "StingerTest.h"

@interface StingerViewController ()

@end

@implementation StingerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Stinger";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)classPrintClick:(id)sender {
    [[StingerTest new] execute_class_print:sender];
}

- (IBAction)print1:(id)sender {
    [[StingerTest new] execute_print1:sender];
}

- (IBAction)print2:(id)sender {
    [[StingerTest new] execute_print2:sender];
}

- (IBAction)test:(id)sender {
    [[StingerTest new] execute_print3:sender];
}

- (IBAction)instanceHook:(id)sender {
    [[StingerTest new] execute_Instance:sender];
}


@end

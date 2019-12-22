//
//  ViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "ViewController.h"
#import "FixEngine.h"
#import "DemoViewController.h"
#import "SubDemoViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [FixEngine startEngine];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)CalculationButtonClick:(id)sender {
    [self.navigationController pushViewController:[DemoViewController new] animated:YES];
}

- (IBAction)gotoSubClass:(id)sender {
    [self.navigationController pushViewController:[SubDemoViewController new] animated:YES];
}

- (IBAction)FixitButtonClick:(UIButton *)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DemoViewController" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [FixEngine evaluateScript:script];
    sender.hidden = YES;
}

@end

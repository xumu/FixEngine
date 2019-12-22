//
//  AspectsViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "AspectsViewController.h"
#import "AspectsTest.h"

@interface AspectsViewController ()

@end

@implementation AspectsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Aspects";
}

- (IBAction)testTmie:(id)sender {
    [[AspectsTest new] execute_print1:sender];
}

- (IBAction)classPrintClick:(id)sender {
    [[AspectsTest new] execute_class_print:sender];
}



@end

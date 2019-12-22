//
//  AOPViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "AOPViewController.h"
#import "AOPLibTest.h"

@interface AOPViewController ()

@end

@implementation AOPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)proxyClick:(id)sender {
    [[AOPLibTest new] testAOP];
}


@end

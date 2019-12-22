//
//  MethodSwizzlingViewController.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "MethodSwizzlingViewController.h"
#import "MethodSwzzlingTest.h"

@interface MethodSwizzlingViewController ()

@end

@implementation MethodSwizzlingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (IBAction)swizzlingButtonClick:(id)sender {
    [MethodSwzzlingTest test];
}

@end

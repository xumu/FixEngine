//
//  MethodSwzzlingTest.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "MethodSwzzlingTest.h"
#import "ClassA.h"

@interface MethodSwzzlingTest()

@end

@implementation MethodSwzzlingTest

+ (void)test {
    [ClassB swizzlingMethodA];
    
    ClassA *classAInstance = [[ClassA alloc] init];
    ClassB *classBInstance = [[ClassB alloc] init];
    
    [classAInstance methodA:@"test"];
    [classBInstance swizzling_MethodA:@"test"];
    [classBInstance methodA:@"test"];
    
}

@end

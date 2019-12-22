//
//  ClassA.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "ClassA.h"
#import "NSObject+Extension.h"

@implementation ClassA

- (void)methodA:(NSString *)name {
    NSLog(@"%@", name);
}

@end

@implementation ClassB

- (void)swizzling_MethodA:(NSString *)name {
    NSLog(@"swizzling_MethodA %@", name);
}

+ (void)swizzlingMethodA {
    [NSObject swizzleMethod:@selector(methodA:) originalClass:ClassB.class targetMethod:@selector(swizzling_MethodA:) targetClass:ClassB.class];
}

@end

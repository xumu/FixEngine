//
//  ClassA.h
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassA : NSObject

- (void)methodA:(NSString *)name;

@end

@interface ClassB : ClassA

- (void)swizzling_MethodA:(NSString *)name;

+ (void)swizzlingMethodA;

@end

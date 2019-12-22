//
//  NSObject+Extension.h
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (Extension)

+ (void)swizzleMethod:(nonnull SEL)originalMethod originalClass:(nonnull Class)originalClass targetMethod:(nonnull SEL)targetMethod targetClass:(nonnull Class)targetClass;

@end

//
//  NSObject+Extension.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/25.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "NSObject+Extension.h"


@implementation NSObject (Extension)

+ (void)swizzleMethod:(nonnull SEL)originalMethod originalClass:(nonnull Class)originalClass targetMethod:(nonnull SEL)targetMethod targetClass:(nonnull Class)targetClass {
    //原始方法的IMP
    Method oMethod = class_getInstanceMethod(originalClass, originalMethod);
    //目标方法的IMP
    Method tMethod = class_getInstanceMethod(targetClass, targetMethod);
    
    BOOL didAddMethod = class_addMethod(originalClass, originalMethod, method_getImplementation(tMethod), method_getTypeEncoding(tMethod));
    if (didAddMethod) {
        class_replaceMethod(targetClass, targetMethod, method_getImplementation(oMethod), method_getTypeEncoding(oMethod));
    }
    else {
        //IMP相互交换，方法的实现也就互相交换了
        method_exchangeImplementations(tMethod, oMethod);
    }
}

@end

//
//  AspectsTest.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "AspectsTest.h"
#import <objc/runtime.h>
#import "Aspects.h"

typedef double (^AspectsTestBlock)(double x, double y);

@interface ClassC : NSObject

@end

@implementation ClassC

+ (void)load {
    // hook @selector(print1:)
    [self aspect_hookSelector:@selector(print1:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo, NSString *s) {
        NSLog(@"---before1 print1: %@", s);
    } error:nil];
    [self aspect_hookSelector:@selector(print1:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo, NSString *s) {
        NSLog(@"---before2 print1: %@", s);
    } error:nil];
    [self aspect_hookSelector:@selector(print1:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo, NSString *s) {
        NSLog(@"---after1 print1: %@", s);
    } error:nil];
    [self aspect_hookSelector:@selector(print1:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo, NSString *s) {
        NSLog(@"---after2 print1: %@", s);
    } error:nil];
    // hook @selector(class_print)
    [object_getClass(self) aspect_hookSelector:@selector(class_print:) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo, NSString *s) {
        [aspectInfo.originalInvocation invoke];
        NSLog(@"---instead class_print: %@", s);
    } error:nil];
    
}

- (void)print1:(NSString *)s{
    NSLog(@"---original print1: %@", s);
}

- (NSString *)print2:(NSString *)s{
    NSLog(@"---original print2: %@", s);
    return [s stringByAppendingString:@"-print2 return"];
}

- (void)print3:(NSString *)s{
    NSLog(@"---original print3: %@", s);
}

- (void)testBlock:(AspectsTestBlock)block {
    NSLog(@"---original testBlock %f", block(5, 15));
}

- (void)print4:(NSString *)s {
    NSLog(@"---original print4: %@", s);
}

+ (void)class_print:(NSString *)s {
    NSLog(@"---original class_print: %@", s);
}


@end

@interface AspectsTest()

@property (nonatomic, strong) ClassC *classCInstance;

@end

@implementation AspectsTest

- (instancetype)init {
    if (self = [super init]) {
        self.classCInstance = [[ClassC alloc] init];
    }
    return self;
}

- (void)execute_class_print:(id)sender {
    [self measureBlock:^{
        [ClassC class_print:@"example"];
    } times:10];
}

- (void)execute_print1:(id)sender {
    [self measureBlock:^{
        [self.classCInstance print1:@"example"];
    } times:100000];
}

- (NSTimeInterval)measureBlock:(void(^)(void))block times:(NSUInteger)times {
    NSDate* tmpStartDate = [NSDate date];
    if (block) {
        for (int i = 0; i < times; i++) {
            block();
        }
    }
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:tmpStartDate];
    NSLog(@"Aspects *** %f ", time);
    return time;
}

@end

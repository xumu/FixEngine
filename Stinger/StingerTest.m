//
//  StingerTest.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/7/26.
//  Copyright © 2018年 F_knight. All rights reserved.
//

#import "StingerTest.h"
#import "Stinger.h"

typedef double (^testBlock)(double x, double y);

@interface ClassD : NSObject

@end

@implementation ClassD

+ (void)load {
    /*
     * hook class method @selector(class_print:)
     */
    [self st_hookClassMethod:@selector(class_print:) option:STOptionBefore usingIdentifier:@"hook_class_print_before" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---before class_print: %@", s);
    }];
    
    /*
     * hook @selector(print1:)
     */
    [self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before1" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---before1 print1: %@", s);
    }];
    
    [self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before2" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---before2 print1: %@", s);
    }];
    
    [self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after1" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---after1 print1: %@", s);
    }];
    
    [self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after2" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---after2 print1: %@", s);
    }];
    
    /*
     * hook @selector(print2:)
     */
    
    __block NSString *oldRet;
    [self st_hookInstanceMethod:@selector(print2:) option:STOptionInstead usingIdentifier:@"hook_print2_instead" withBlock:^NSString * (id<StingerParams> params, NSString *s) {
        [params invokeAndGetOriginalRetValue:&oldRet];
        NSString *newRet = [oldRet stringByAppendingString:@" ++ new-st_instead"];
        NSLog(@"---instead print2 old ret: (%@) / new ret: (%@)", oldRet, newRet);
        return newRet;
    }];
    
    [self st_hookInstanceMethod:@selector(print2:) option:STOptionAfter usingIdentifier:@"hook_print2_after1" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"---after1 print2 self:%@ SEL: %@ p: %@",[params slf], NSStringFromSelector([params sel]), s);
    }];
    
    /*
     * hook @selector(testBlock:) test block
     */
    
    [self st_hookInstanceMethod:@selector(testBlock:) option:STOptionAfter usingIdentifier:@"hook_testBlock_after1" withBlock:^(id<StingerParams> params, testBlock block) {
        NSLog(@"test block value %f", block(2, 3));
    }];
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

- (void)testBlock:(testBlock)block {
    NSLog(@"---original testBlock %f", block(5, 15));
}

+ (void)class_print:(NSString *)s {
    NSLog(@"---original class_print: %@", s);
}

- (void)print4:(NSString *)s {
    NSLog(@"---original print4: %@", s);
}

@end

@interface StingerTest()

@property (nonatomic, strong) ClassD *classDInstance;

@end

@implementation StingerTest

- (instancetype)init {
    if (self = [super init]) {
        self.classDInstance = [[ClassD alloc] init];
    }
    return self;
}

- (void)execute_class_print:(id)sender {
    [self measureBlock:^{
        [ClassD class_print:@"example"];
    } times:10];
}

- (void)execute_print1:(id)sender {
    [self measureBlock:^{
        [self.classDInstance print1:@"example"];
    } times:100000];
}

- (void)execute_print2:(id)sender {
    [self measureBlock:^{
        NSString *newRet = [self.classDInstance print2:@"example"];
        NSLog(@"---print2 new ret: %@", newRet);
    } times:10];
}

- (void)execute_print3:(id)sender {
    [self.classDInstance testBlock:^double(double x, double y) {
        return x + y;
    }];
}

- (void)execute_Instance:(id)sender {
    ClassD *classDInstance = [[ClassD alloc] init];
    [classDInstance st_hookInstanceMethod:@selector(print4:) option:STOptionInstead usingIdentifier:@"hook_instance_print4" withBlock:^(id<StingerParams> params, NSString *s) {
        NSLog(@"--- hook Print4 instance ----)");
    }];
    
    [classDInstance print4:nil];
    [[ClassD new] print4:nil];
}

- (NSTimeInterval)measureBlock:(void(^)(void))block times:(NSUInteger)times {
    NSDate* tmpStartDate = [NSDate date];
    if (block) {
        for (int i = 0; i < times; i++) {
            block();
        }
    }
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:tmpStartDate];
    NSLog(@"Stinger *** %f ", time);
    return time;
}

@end

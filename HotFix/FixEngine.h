//
//  FixEngine.h
//  SimpleHotFix
//
//  Created by F_knight on 2018/9/30.
//  Copyright © 2018 F_knight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface FixEngine : NSObject

+ (void)startEngine;

+ (JSValue *)evaluateScriptWithPath:(NSString *)filePath;

+ (JSValue *)evaluateScript:(NSString *)script;

+ (JSContext *)context;

@end


@interface FEBoxing : NSObject
@property (nonatomic) id obj;
@property (nonatomic) void *pointer;
@property (nonatomic) Class cls;
@property (nonatomic, weak) id weakObj;
@property (nonatomic, assign) id assignObj;
- (id)unbox;
- (void *)unboxPointer;
- (Class)unboxClass;
@end


NS_ASSUME_NONNULL_END

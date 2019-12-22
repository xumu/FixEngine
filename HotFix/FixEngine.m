//
//  FixEngine.m
//  SimpleHotFix
//
//  Created by F_knight on 2018/9/30.
//  Copyright © 2018 F_knight. All rights reserved.
//

#import "FixEngine.h"
#import <objc/runtime.h>
#import "Aspects.h"

@implementation FEBoxing

#define FEBOXING_GEN(_name, _prop, _type) \
+ (instancetype)_name:(_type)obj  \
{   \
FEBoxing *boxing = [[FEBoxing alloc] init]; \
boxing._prop = obj;   \
return boxing;  \
}

FEBOXING_GEN(boxObj, obj, id)
FEBOXING_GEN(boxPointer, pointer, void *)
FEBOXING_GEN(boxClass, cls, Class)
FEBOXING_GEN(boxWeakObj, weakObj, id)
FEBOXING_GEN(boxAssignObj, assignObj, id)

- (id)unbox
{
    if (self.obj) return self.obj;
    if (self.weakObj) return self.weakObj;
    if (self.assignObj) return self.assignObj;
    if (self.cls) return self.cls;
    return self;
}
- (void *)unboxPointer
{
    return self.pointer;
}
- (Class)unboxClass
{
    return self.cls;
}
@end

static JSContext *_context;
static NSString *_scriptRootDir;
static NSRegularExpression *_regex;
static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSString *_replaceStr = @".__c(\"$1\")(";
static NSObject *_nilObj;
static NSObject *_nullObj;

static NSMutableDictionary *_TMPMemoryPool;
static NSMutableDictionary *_JSOverideMethods;

static void (^_exceptionBlock)(NSString *log) = ^void(NSString *log) {
    NSCAssert(NO, log);
};


typedef struct {double d;} __FelixDouble__;
typedef struct {float f;} __FelixFloat__;

@implementation FixEngine

+ (void)startEngine {
    [self context][@"_OC_defineClass"] = ^(NSString *className, JSValue *instanceMethods, JSValue *classMethods) {
        return [self defineClassWithClassName:className instanceMethods:instanceMethods classMethods:classMethods];
    };
    
    [self context][@"_OC_callI"] = ^id(JSValue *obj, NSString *selectorName, JSValue *arguments, BOOL isSuper) {
        return [self callSelectorWithClassName:nil selectorName:selectorName arguments:arguments instance:obj isSuper:isSuper];
    };
    
    [self context][@"_OC_callC"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments) {
        return [self callSelectorWithClassName:className selectorName:selectorName arguments:arguments instance:nil isSuper:NO];
    };
    
    [self context][@"_OC_formatJSToOC"] = ^id(JSValue *obj) {
        return formatJSToOC(obj);
    };
    
    [self context][@"_OC_formatOCToJS"] = ^id(JSValue *obj) {
        return formatOCToJS([obj toObject]);
    };
    
    _nullObj = [[NSObject alloc] init];
    _nilObj = [[NSObject alloc] init];
    [self context][@"_OC_null"] = formatOCToJS(_nullObj);
    
    [self context][@"releaseTmpObj"] = ^void(JSValue *jsVal) {
        if ([[jsVal toObject] isKindOfClass:[NSDictionary class]]) {
            void *pointer =  [(FEBoxing *)([jsVal toObject][@"__obj"]) unboxPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            @synchronized(_TMPMemoryPool) {
                [_TMPMemoryPool removeObjectForKey:[NSNumber numberWithInteger:[obj hash]]];
            }
        }
    };
    
    [self context][@"__weak"] = ^id(JSValue *jsval) {
        id obj = formatJSToOC(jsval);
        return [[JSContext currentContext][@"_formatOCToJS"] callWithArguments:@[formatOCToJS([FEBoxing boxWeakObj:obj])]];
    };
    
    [self context][@"__strong"] = ^id(JSValue *jsval) {
        id obj = formatJSToOC(jsval);
        return [[JSContext currentContext][@"_formatOCToJS"] callWithArguments:@[formatOCToJS(obj)]];
    };
    
    [self context][@"_OC_log"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            id obj = formatJSToOC(jsVal);
            NSLog(@"JSPatch.log: %@", obj == _nilObj ? nil : (obj == _nullObj ? [NSNull null]: obj));
        }
    };
    
    [self context][@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
        _exceptionBlock([NSString stringWithFormat:@"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]]);
    };
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"FEPatch" ofType:@"js"];
    if (!path) _exceptionBlock(@"can't find FEPatch.js");
    NSString *jsCore = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:path] encoding:NSUTF8StringEncoding];
    
    if ([[self context] respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
        [[self context] evaluateScript:jsCore withSourceURL:[NSURL URLWithString:@"main.js"]];
    }
    else {
        [[self context] evaluateScript:jsCore];
    }
    
}

+ (JSContext *)context {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _context = [[JSContext alloc] init];
        [_context setExceptionHandler:^(JSContext *context, JSValue *value) {
            NSLog(@"JSContext:%@ ---- JSValue:%@", context, value);
        }];
    });
    return _context;
}

+ (JSValue *)evaluateScript:(NSString *)script
{
    return [self _evaluateScript:script withSourceURL:[NSURL URLWithString:@"main.js"]];
}

+ (JSValue *)evaluateScriptWithPath:(NSString *)filePath
{
    _scriptRootDir = [filePath stringByDeletingLastPathComponent];
    return [self _evaluateScriptWithPath:filePath];
}

+ (JSValue *)_evaluateScriptWithPath:(NSString *)filePath
{
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return [self _evaluateScript:script withSourceURL:[NSURL URLWithString:[filePath lastPathComponent]]];
}

+ (JSValue *)_evaluateScript:(NSString *)script withSourceURL:(NSURL *)resourceURL
{
    if (!script || ![JSContext class]) {
        _exceptionBlock(@"script is nil");
        return nil;
    }
    
    if (!_context) {
        [self startEngine];
    }
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@";(function(){try{\n%@\n}catch(e){_OC_catch(e.message, e.stack)}})();", [_regex stringByReplacingMatchesInString:script options:0 range:NSMakeRange(0, script.length) withTemplate:_replaceStr]];
    @try {
        if ([_context respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
            return [_context evaluateScript:formatedScript withSourceURL:resourceURL];
        } else {
            return [_context evaluateScript:formatedScript];
        }
    }
    @catch (NSException *exception) {
        _exceptionBlock([NSString stringWithFormat:@"%@", exception]);
    }
    return nil;
}

+ (void)_invocation:(NSInvocation *)invo signature:(NSMethodSignature *)sig setArgument:(id)obj origArgument:(JSValue *)origArgument atIndex:(NSInteger)index markArray:(NSMutableArray *)markArray
{
    const char *argumentType = [sig getArgumentTypeAtIndex:index];
    if (argumentType[0] == _C_CONST) argumentType++;
    
    switch (argumentType[0]) {
            // 对 primative 类型的处理下
            #define __CALL_ARGTYPE_CASE(_typeString, _type, _selector) \
            case _typeString: {                              \
                _type value = [obj _selector];                     \
                [invo setArgument:&value atIndex:index];\
                break; \
            }
            
            __CALL_ARGTYPE_CASE('c', char, charValue)
            __CALL_ARGTYPE_CASE('C', unsigned char, unsignedCharValue)
            __CALL_ARGTYPE_CASE('s', short, shortValue)
            __CALL_ARGTYPE_CASE('S', unsigned short, unsignedShortValue)
            __CALL_ARGTYPE_CASE('i', int, intValue)
            __CALL_ARGTYPE_CASE('I', unsigned int, unsignedIntValue)
            __CALL_ARGTYPE_CASE('l', long, longValue)
            __CALL_ARGTYPE_CASE('L', unsigned long, unsignedLongValue)
            __CALL_ARGTYPE_CASE('q', long long, longLongValue)
            __CALL_ARGTYPE_CASE('Q', unsigned long long, unsignedLongLongValue)
            __CALL_ARGTYPE_CASE('f', float, floatValue)
            __CALL_ARGTYPE_CASE('d', double, doubleValue)
            __CALL_ARGTYPE_CASE('B', BOOL, boolValue)
        case ':': {
            SEL value = nil;
            if (obj != _nilObj) {
                value = NSSelectorFromString(obj);
            }
            [invo setArgument:&value atIndex:index];
            break;
        }
        case '{': {
            NSString *typeString = extractTypeName([NSString stringWithUTF8String:argumentType]);
            #define FE_CALL_ARG_STRUCT(_type, _methodName) \
            if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                _type value = [origArgument _methodName];  \
                [invo setArgument:&value atIndex:index];  \
                break; \
            }
            FE_CALL_ARG_STRUCT(CGRect, toRect)
            FE_CALL_ARG_STRUCT(CGPoint, toPoint)
            FE_CALL_ARG_STRUCT(CGSize, toSize)
            FE_CALL_ARG_STRUCT(NSRange, toRange)
            break;
        }
        case '*':
        case '^': {
            if ([obj isKindOfClass:[FEBoxing class]]) {
                void *value = [((FEBoxing *)obj) unboxPointer];
                
                if (argumentType[1] == '@') {
                    if (!_TMPMemoryPool) {
                        _TMPMemoryPool = [[NSMutableDictionary alloc] init];
                    }
                    
                    memset(value, 0, sizeof(id));
                    [markArray addObject:obj];
                }
                
                [invo setArgument:&value atIndex:index];
                break;
            }
        }
        case '#': {
            if ([obj isKindOfClass:[FEBoxing class]]) {
                Class value = [((FEBoxing *)obj) unboxClass];
                [invo setArgument:&value atIndex:index];
                break;
            }
        }
        default:
            if (obj == _nullObj) {
                obj = [NSNull null];
                [invo setArgument:&obj atIndex:index];
                break;
            }
            if (obj == _nilObj ||
                ([obj isKindOfClass:[NSNumber class]] && strcmp([obj objCType], "c") == 0 && ![obj boolValue])) {
                obj = nil;
                [invo setArgument:&obj atIndex:index];
                break;
            }
            static const char *blockType = @encode(typeof(^{}));
            if (!strcmp(argumentType, blockType)) {
                __autoreleasing id cb = genCallbackBlock(origArgument);
                [invo setArgument:&cb atIndex:index];
            }
            else {
                if ([obj isMemberOfClass:[FEBoxing class]]) {
                    obj = (__bridge id)[((FEBoxing *)obj) unboxPointer];
                    [invo setArgument:&obj atIndex:index];
                }else{
                    [invo setArgument:&obj atIndex:index];
                }
            }
            break;
    }
}

static NSRegularExpression *countArgRegex;

+ (NSDictionary *)defineClassWithClassName:(NSString *)className instanceMethods:(JSValue *)instanceMethods classMethods:(JSValue *)classMethohds {
    className = trim(className);
    Class cls = NSClassFromString(className);
    if (!cls) {
        return nil;
    }
    
    for (int i = 0; i < 2; i++) {
        BOOL isInstance = i == 0;
        JSValue *jsMethods = isInstance ? instanceMethods : classMethohds;
        Class currCls = isInstance ? cls : objc_getMetaClass(className.UTF8String);
        NSDictionary *methodDic = [jsMethods toDictionary];
        for (NSString *jsMethodName in methodDic.allKeys) {
            JSValue *jsMethodArr = [jsMethods valueForProperty:jsMethodName];
            int numberOfArg = [jsMethodArr[0] toInt32];
            NSString *tmpJSMethodName = [jsMethodName stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
            NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
            selectorName = [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
            
            if (!countArgRegex) {
                countArgRegex = [NSRegularExpression regularExpressionWithPattern:@":" options:NSRegularExpressionCaseInsensitive error:nil];
            }
            NSUInteger numberOfMatches = [countArgRegex numberOfMatchesInString:selectorName options:0 range:NSMakeRange(0, [selectorName length])];
            if (numberOfMatches < numberOfArg) {
                selectorName = [selectorName stringByAppendingString:@":"];
            }
            
            JSValue *jsMethod = jsMethodArr[1];
            SEL selector = NSSelectorFromString(selectorName);
            if (!_JSOverideMethods[NSStringFromClass(currCls)][selectorName]) {
                _initFEOverideMethods(NSStringFromClass(currCls));
                _JSOverideMethods[NSStringFromClass(currCls)][selectorName] = jsMethod;
                [currCls aspect_hookSelector:selector withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo){
                    NSMutableArray *jsMethosArguments = [NSMutableArray arrayWithObject:aspectInfo.instance];
                    [jsMethosArguments addObjectsFromArray:aspectInfo.arguments];
                    [jsMethod callWithArguments:_formatOCToJSList(jsMethosArguments)];
                } error:nil];
            }
        }
    }
    
    return @{@"cls": className};
}

+ (id)callSelectorWithClassName:(NSString *)className selectorName:(NSString *)selectorName arguments:(JSValue *)arguments instance:(JSValue *)instance isSuper:(BOOL)isSuper{
    if (instance) instance = formatJSToOC(instance);
    id argumentsObj = formatJSToOC(arguments);
    
    if (instance && [selectorName isEqualToString:@"toJS"]) {
        if ([instance isKindOfClass:[NSString class]] || [instance isKindOfClass:[NSDictionary class]] || [instance isKindOfClass:[NSArray class]]) {
            return _unboxOCObjectToJS(instance);
        }
    }
    
    Class cls = className ? NSClassFromString(className) : [instance class];
    
    if ([selectorName hasPrefix:@"ORIG"]) {
        selectorName = [@"aspects__" stringByAppendingString:[selectorName substringFromIndex:4]];
    }
    SEL selector = NSSelectorFromString(selectorName);
    
    if (isSuper) {
        NSString *superSelectorName = [NSString stringWithFormat:@"SUPER_%@", selectorName];
        SEL superSelector = NSSelectorFromString(superSelectorName);
        
        Class superCls = [cls superclass];
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP superIMP = method_getImplementation(superMethod);
        
        class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
        
        JSValue *overrideFunction = _JSOverideMethods[NSStringFromClass(superCls)][selectorName];
        if (overrideFunction) {
            if (!_JSOverideMethods[NSStringFromClass(cls)][superSelectorName]) {
                _initFEOverideMethods(NSStringFromClass(cls));
                _JSOverideMethods[NSStringFromClass(cls)][superSelectorName] = overrideFunction;
                [cls aspect_hookSelector:superSelector withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo){
                    NSMutableArray *jsMethosArguments = [NSMutableArray arrayWithObject:aspectInfo.instance];
                    [jsMethosArguments addObjectsFromArray:aspectInfo.arguments];
                    [overrideFunction callWithArguments:_formatOCToJSList(jsMethosArguments)];
                } error:nil];
            }
        }
        
        selector = superSelector;
    }
    
    NSMutableArray *_markArray = [NSMutableArray array];
    
    NSInvocation *invo;
    NSMethodSignature *methodSignature;
    if (instance) {
        methodSignature = [cls instanceMethodSignatureForSelector:selector];
        NSCAssert(methodSignature, @"unrecognized selector %@ for instance %@", selectorName, instance);
        invo = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invo setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        NSCAssert(methodSignature, @"unrecognized selector %@ for class %@", selectorName, className);
        invo= [NSInvocation invocationWithMethodSignature:methodSignature];
        [invo setTarget:cls];
    }
    [invo setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        [self _invocation:invo signature:methodSignature setArgument:argumentsObj[i-2] origArgument:arguments[i-2] atIndex:i markArray:_markArray];
    }
    
    [invo invoke];
    if ([_markArray count] > 0) {
        for (FEBoxing *box in _markArray) {
            void *pointer = [box unboxPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            if (obj) {
                @synchronized(_TMPMemoryPool) {
                    [_TMPMemoryPool setObject:obj forKey:[NSNumber numberWithInteger:[obj hash]]];
                }
            }
        }
    }
    
    if (methodSignature.methodReturnLength) {
        char returnType[255];
        strcpy(returnType, [methodSignature methodReturnType]);
        
        // Restore the return type
        if (strcmp(returnType, @encode(__FelixDouble__)) == 0) {
            strcpy(returnType, @encode(double));
        }
        if (strcmp(returnType, @encode(__FelixFloat__)) == 0) {
            strcpy(returnType, @encode(float));
        }
        
        id returnValue;
        if (strncmp(returnType, "v", 1) != 0) {
            if (strncmp(returnType, "@", 1) == 0) {
                void *result;
                [invo getReturnValue:&result];
                
                //For performance, ignore the other methods prefix with alloc/new/copy/mutableCopy
                if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
                    [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                    returnValue = (__bridge_transfer id)result;
                } else {
                    returnValue = (__bridge id)result;
                }
                
                return formatOCToJS(returnValue);
            }
            else {
                switch (returnType[0] == _C_CONST ? returnType[1] : returnType[0]) {
                  
                  #define __CALL_RETYPE_CASE__(_typeString, _type) \
                  case _typeString: {                              \
                    _type tempResultSet; \
                    [invo getReturnValue:&tempResultSet];\
                    returnValue = @(tempResultSet); \
                    break; \
                  }
                        
                 __CALL_RETYPE_CASE__('c', char)
                 __CALL_RETYPE_CASE__('C', unsigned char)
                 __CALL_RETYPE_CASE__('s', short)
                 __CALL_RETYPE_CASE__('S', unsigned short)
                 __CALL_RETYPE_CASE__('i', int)
                 __CALL_RETYPE_CASE__('I', unsigned int)
                 __CALL_RETYPE_CASE__('l', long)
                 __CALL_RETYPE_CASE__('L', unsigned long)
                 __CALL_RETYPE_CASE__('q', long long)
                 __CALL_RETYPE_CASE__('Q', unsigned long long)
                 __CALL_RETYPE_CASE__('f', float)
                 __CALL_RETYPE_CASE__('d', double)
                 __CALL_RETYPE_CASE__('B', BOOL)
                        
                    case '{': {
                        NSString *typeString = extractTypeName([NSString stringWithUTF8String:returnType]);
                        #define FE_CALL_RET_STRUCT(_type, _methodName) \
                        if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                          _type result;   \
                          [invo getReturnValue:&result];    \
                          return [JSValue _methodName:result inContext:[JSContext currentContext]];    \
                        }
                        FE_CALL_RET_STRUCT(CGRect, valueWithRect)
                        FE_CALL_RET_STRUCT(CGPoint, valueWithPoint)
                        FE_CALL_RET_STRUCT(CGSize, valueWithSize)
                        FE_CALL_RET_STRUCT(NSRange, valueWithRange)
                        break;
                    }
                    case '*':
                    case '^': {
                        void *result;
                        [invo getReturnValue:&result];
                        returnValue = formatOCToJS([FEBoxing boxPointer:result]);
                        break;
                    }
                    case '#': {
                        Class result;
                        [invo getReturnValue:&result];
                        returnValue = formatOCToJS([FEBoxing boxClass:result]);
                        break;
                    }
                }
                return returnValue;
            }
        }
    }
    
    return nil;
}

#pragma mark - Object format
static id formatOCToJS(id obj)
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDate class]]) {
        return _wrapObj([FEBoxing boxObj:obj]);
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return obj;
    }
    if ([obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[JSValue class]]) {
        return obj;
    }
    return _wrapObj(obj);
}

static id formatJSToOC(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return _nilObj;
    
    if ([obj isKindOfClass:[FEBoxing class]]) return [obj unbox];
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:formatJSToOC(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if (obj[@"__obj"]) {
            id ocObj = [obj objectForKey:@"__obj"];
            if ([ocObj isKindOfClass:[FEBoxing class]]) return [ocObj unbox];
            return ocObj;
        } else if (obj[@"__clsName"]) {
            return NSClassFromString(obj[@"__clsName"]);
        }
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:formatJSToOC(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}

static id _formatOCToJSList(NSArray *list)
{
    NSMutableArray *arr = [NSMutableArray new];
    for (id obj in list) {
        [arr addObject:formatOCToJS(obj)];
    }
    return arr;
}

static NSDictionary *_wrapObj(id obj)
{
    if (!obj || obj == _nilObj) {
        return @{@"__isNil": @(YES)};
    }
    return @{@"__obj": obj, @"__clsName": NSStringFromClass([obj isKindOfClass:[FEBoxing class]] ? [[((FEBoxing *)obj) unbox] class]: [obj class])};
}

static id _unboxOCObjectToJS(id obj)
{
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:_unboxOCObjectToJS(obj[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:_unboxOCObjectToJS(obj[key]) forKey:key];
        }
        return newDict;
    }
    if ([obj isKindOfClass:[NSString class]] ||[obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[NSDate class]]) {
        return obj;
    }
    return _wrapObj(obj);
}

static id genCallbackBlock(JSValue *jsVal)
{
    #define BLK_TRAITS_ARG(_idx, _paramName) \
    if (_idx < argTypes.count) { \
      NSString *argType = trim(argTypes[_idx]); \
      if (blockTypeIsScalarPointer(argType)) { \
        [list addObject:formatOCToJS([FEBoxing boxPointer:_paramName])]; \
      } else if (blockTypeIsObject(trim(argTypes[_idx]))) {  \
        [list addObject:formatOCToJS((__bridge id)_paramName)]; \
      } else {  \
        [list addObject:formatOCToJS([NSNumber numberWithLongLong:(long long)_paramName])]; \
      }   \
    }
    
    NSArray *argTypes = [[jsVal[@"args"] toString] componentsSeparatedByString:@","];
    id cb = ^id(void *p0, void *p1, void *p2, void *p3, void *p4, void *p5) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        BLK_TRAITS_ARG(0, p0)
        BLK_TRAITS_ARG(1, p1)
        BLK_TRAITS_ARG(2, p2)
        BLK_TRAITS_ARG(3, p3)
        BLK_TRAITS_ARG(4, p4)
        BLK_TRAITS_ARG(5, p5)
        JSValue *ret = [jsVal[@"cb"] callWithArguments:list];
        return formatJSToOC(ret);
    };
    
    return cb;
}

#pragma mark - Utils
static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *extractTypeName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    int firstValidIndex = 0;
    for (int i = 0; i< typeString.length; i++) {
        char c = [typeString characterAtIndex:i];
        if (c == '{' || c=='_') {
            firstValidIndex++;
        }else {
            break;
        }
    }
    return [typeString substringFromIndex:firstValidIndex];
}

static BOOL blockTypeIsScalarPointer(NSString *typeString)
{
    NSUInteger location = [typeString rangeOfString:@"*"].location;
    NSString *typeWithoutAsterisk = trim([typeString stringByReplacingOccurrencesOfString:@"*" withString:@""]);
    
    return (location == typeString.length-1 &&
            !NSClassFromString(typeWithoutAsterisk));
}

static BOOL blockTypeIsObject(NSString *typeString)
{
    return [typeString rangeOfString:@"*"].location != NSNotFound || [typeString isEqualToString:@"id"];
}

static void _initFEOverideMethods(NSString *clsName) {
    if (!_JSOverideMethods) {
        _JSOverideMethods = [[NSMutableDictionary alloc] init];
    }
    if (!_JSOverideMethods[clsName]) {
        _JSOverideMethods[clsName] = [[NSMutableDictionary alloc] init];
    }
}

@end

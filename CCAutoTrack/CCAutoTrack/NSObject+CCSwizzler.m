//
//  NSObject+CCSwizzler.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "NSObject+CCSwizzler.h"
#import <objc/runtime.h>

@implementation NSObject (CCSwizzler)

+ (BOOL)cc_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL {
    // 获取原始方法
    Method originalMethod = class_getInstanceMethod(self, originalSEL);
    if (!originalMethod) {
        return NO;
    }
    
    // 获取要交换的方法
    Method alternateMethod = class_getInstanceMethod(self, alternateSEL);
    if (!alternateMethod) {
        return NO;
    }
    
    // 获取原始方法的实现
    IMP originalIMP = method_getImplementation(originalMethod);
    // 获取原始方法的类型
    const char *originalMethodType = method_getTypeEncoding(originalMethod);
    if (class_addMethod(self, originalSEL, originalIMP, originalMethodType)) {
        // 如果添加成功，重新获取originalSEL实例方法
        originalMethod = class_getInstanceMethod(self, originalSEL);
    }
    
    // 获取要交换的方法实现
    IMP alternateIMP = method_getImplementation(alternateMethod);
    // 获取要交换方法的类型
    const char *alternateMethodType = method_getTypeEncoding(alternateMethod);
    if (class_addMethod(self, alternateSEL, alternateIMP, alternateMethodType)) {
        // 如果添加成功，重新获取alternateSEL实例方法
        alternateMethod = class_getInstanceMethod(self, alternateSEL);
    }
    
    // 交换方法的实现
    method_exchangeImplementations(originalMethod, alternateMethod);
    return YES;
}

@end

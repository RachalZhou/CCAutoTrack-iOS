//
//  CCAutoTrackDynamicDelegate.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackDynamicDelegate.h"
#import "CCAutoTrackSDK.h"
#import <objc/runtime.h>

/// delegate对象的子类前缀
static NSString *const kCCAutoTrackDelegatePrefix = @"cn.CCAutoTrack.";

/// tableview:didSelectRowAtIndexPath:方法指针类型
typedef void (*CCAutoTrackDidSelectImplementation)(id, SEL, UITableView *, NSIndexPath *);

@implementation CCAutoTrackDynamicDelegate

+ (void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    
    // 当delegate对象没有实现tableView:didSelectRowAtIndexPath:方法时，直接返回
    if (![delegate respondsToSelector:originalSelector]) {
        return;
    }
    
    // 动态创建一个新类
    Class originalClass = object_getClass(delegate);
    NSString *originalClassName = NSStringFromClass(originalClass);
    // 当delegate对象已经是一个动态创建的类时，无须重复设置，直接返回
    if ([originalClassName hasPrefix:kCCAutoTrackDelegatePrefix]) {
        return;
    }
    
    NSString *subclassName = [kCCAutoTrackDelegatePrefix stringByAppendingString:originalClassName];
    Class subclass = NSClassFromString(subclassName);
    if (!subclass) {
        // 注册一个新的子类，父类是originalClass
        subclass = objc_allocateClassPair(originalClass, subclassName.UTF8String, 0);
        
        // 在subClass中添加tableView:didSelectRowAtIndexPath:方法
        Method method = class_getInstanceMethod(self, originalSelector);
        IMP imp = method_getImplementation(method);
        const char *type = method_getTypeEncoding(method);
        if (!class_addMethod(subclass, originalSelector, imp, type)) {
            NSLog(@"Can not copy method destination selector to %@ as it already exists.", NSStringFromSelector(originalSelector));
        }
        
        // 在subClass中添加class方法
        Method classMethod = class_getInstanceMethod(self, @selector(cc_class));
        IMP classImp = method_getImplementation(classMethod);
        const char *classType = method_getTypeEncoding(classMethod);
        if (!class_addMethod(subclass, @selector(class), classImp, classType)) {
            NSLog(@"Can not copy method destination selector -(void)class as it already exists.");
        }
        
        // 子类和原始类必须大小相同
        if (class_getInstanceSize(originalClass) != class_getInstanceSize(subclass)) {
            NSLog(@"Can not create subclass of delegate, because the created subclass is not the same size. %@", NSStringFromClass(originalClass));
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return;
        }
        
        // 注册新创建的子类
        objc_registerClassPair(subclass);
    }
    
    if (object_setClass(delegate, subclass)) {
        NSLog(@"Successfully created Delegate Proxy automatically.");
    }
}

#pragma mark - 实现didSelectRowAtIndexPath方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    // 第一步：获取原始类
    Class class = object_getClass(tableView.delegate);
    NSString *className = [NSStringFromClass(class) stringByReplacingOccurrencesOfString:kCCAutoTrackDelegatePrefix withString:@""];
    Class originalClass = objc_getClass([className UTF8String]);
    
    // 第二步：调用开发者自己实现的方法
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP originalImp = method_getImplementation(originalMethod);
    if (originalImp) {
        ((CCAutoTrackDidSelectImplementation)originalImp)(tableView.delegate, originalSelector, tableView, indexPath);
    }
    
    // 第三步：埋点
    // 触发$AppClick
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

#pragma mark - 实现class方法
- (Class)cc_class {
    // 获取类对象
    Class class = object_getClass(self);
    // 获取原始类名
    NSString *className = [NSStringFromClass(class) stringByReplacingOccurrencesOfString:kCCAutoTrackDelegatePrefix withString:@""];
    // 通过字符串获取类，并返回
    return objc_getClass([className UTF8String]);
}

@end

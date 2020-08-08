//
//  UITableView+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UITableView+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackSDK.h"
#import "CCAutoTrackDynamicDelegate.h"
#import "CCAutoTrackDelegateProxy.h"
#import "UIScrollView+CCAutoTrack.h"
#import <objc/message.h>

@implementation UITableView (CCAutoTrack)

+ (void)load {
    [UITableView cc_swizzleMethod:@selector(setDelegate:) withMethod:@selector(cc_setDelegate:)];
}

- (void)cc_setDelegate:(id<UITableViewDelegate>)delegate {
    // 方法一：方法交换
//    // 调用原来的实现
//    [self cc_setDelegate:delegate];
//    // 交换delegate对象中的tableView:didSelectRowAtIndexPath:方法
//    [self cc_swizzleDidSelectRowAtIndexPathMethodWithDelegate:delegate];
    
    // 方法二：动态子类
//    // 调用原来的实现
    [self cc_setDelegate:delegate];
    [CCAutoTrackDynamicDelegate proxyWithTableViewDelegate:delegate];
    
    // 方法三：消息转发
    // 销毁保存的委托对象
    self.cc_delegateProxy = nil;
    if (delegate) {
        CCAutoTrackDelegateProxy *proxy = [CCAutoTrackDelegateProxy proxyWithTableViewDelegate:delegate];
        self.cc_delegateProxy = proxy;

        //调用原始方法，将代理设置为委托对象
        [self cc_setDelegate:proxy];
    } else {
        //调用原始方法，将代理设置为nil
        [self cc_setDelegate:nil];
    }
}

#pragma mark - 方法交换

- (void)cc_swizzleDidSelectRowAtIndexPathMethodWithDelegate:(id)delegate {
    // 获取delegate对象的类
    Class delegateClass = [delegate class];
    
    SEL sourceSelector = @selector(tableView:didSelectRowAtIndexPath:);
    // 当delegate对象没有实现tableView:didSelectRowAtIndexPath:方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }
    
    SEL destinationSelector = NSSelectorFromString(@"cc_tableView:didSelectRowAtIndexPath:");
    // 当 delegate 中已经存在了 cc_tableView:didSelectRowAtIndexPath: 方法，那就说明已经进行过 swizzle 了，因此就可以直接返回，不再进行 swizzle
    if ([delegate respondsToSelector:destinationSelector]) {
        return;
    }
    
    Method sourceMethod = class_getInstanceMethod(delegateClass, sourceSelector);
    const char * sourceMethodType = method_getTypeEncoding(sourceMethod);
    
    // 当该类中已经存在了相同的方法时，会失败。但是前面已经判断过是否存在，因此，此处一定会添加成功
    if (!class_addMethod(delegateClass, destinationSelector, (IMP)cc_tableViewDidSelectRow, sourceMethodType)) {
        NSLog(@"Add %@ to %@ error", NSStringFromSelector(destinationSelector), delegateClass);
        return;
    }
    
    // 方法添加成功之后，进行交换
    [delegateClass cc_swizzleMethod:sourceSelector withMethod:destinationSelector];
}

static void cc_tableViewDidSelectRow(id object, SEL selector, UITableView *tableView, NSIndexPath *indexPath) {
    SEL destinationSelector = NSSelectorFromString(@"cc_tableView:didSelectRowAtIndexPath:");
    // 通过消息发送，调用原来的tableView:didSelectRowAtIndexPath:方法实现
    ((void(*)(id, SEL, id, id))objc_msgSend)(object, destinationSelector, tableView, indexPath);
    
    // 触发$AppClick
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

@end

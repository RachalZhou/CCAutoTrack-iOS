//
//  CCAutoTrackDelegateProxy.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackDelegateProxy.h"
#import "CCAutoTrackSDK.h"

@interface CCAutoTrackDelegateProxy ()

/// 保存delegate对象
@property (nonatomic, weak) id delegate;

@end

@implementation CCAutoTrackDelegateProxy

+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    CCAutoTrackDelegateProxy *proxy = [CCAutoTrackDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

+ (instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate {
    CCAutoTrackDelegateProxy *proxy = [CCAutoTrackDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    // 返回delegate对象中对应的方法签名
    return [(NSObject *)self.delegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 先执行delegate中的方法
    [invocation invokeWithTarget:self.delegate];
    
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        // 判断UITableViewCell点击事件的代理方法
        // 替换方法
        invocation.selector = @selector(cc_tableView:didSelectRowAtIndexPath:);
        // 执行采集数据的方法
        [invocation invokeWithTarget:self];
    } else if (invocation.selector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        // 判断UICollectionViewCell点击事件的代理方法
        // 替换方法
        invocation.selector = @selector(cc_collectionView:didSelectItemAtIndexPath:);
        // 执行采集数据的方法
        [invocation invokeWithTarget:self];
    }
}

- (void)cc_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

- (void)cc_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}

@end

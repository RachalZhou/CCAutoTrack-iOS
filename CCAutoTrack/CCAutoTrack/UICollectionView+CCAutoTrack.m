//
//  UICollectionView+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UICollectionView+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackDelegateProxy.h"
#import "UIScrollView+CCAutoTrack.h"

@implementation UICollectionView (CCAutoTrack)

+ (void)load {
    [UICollectionView cc_swizzleMethod:@selector(setDelegate:) withMethod:@selector(cc_setDelegate:)];
}

- (void)cc_setDelegate:(id<UICollectionViewDelegate>)delegate {
    // 使用消息转发实现
    self.cc_delegateProxy = nil;
    if (delegate) {
        CCAutoTrackDelegateProxy *proxy = [CCAutoTrackDelegateProxy proxyWithCollectionViewDelegate:delegate];
        self.cc_delegateProxy = proxy;
        [self cc_setDelegate:proxy];
    } else {
        [self cc_setDelegate:nil];
    }
}

@end

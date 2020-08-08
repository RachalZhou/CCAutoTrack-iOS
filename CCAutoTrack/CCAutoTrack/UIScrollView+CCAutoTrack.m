//
//  UIScrollView+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIScrollView+CCAutoTrack.h"
#import <objc/runtime.h>

@implementation UIScrollView (CCAutoTrack)

- (void)setCc_delegateProxy:(CCAutoTrackDelegateProxy *)cc_delegateProxy {
    objc_setAssociatedObject(self, @selector(cc_delegateProxy), cc_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CCAutoTrackDelegateProxy *)cc_delegateProxy {
    return objc_getAssociatedObject(self, @selector(cc_delegateProxy));
}

@end

//
//  UIControl+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIControl+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackSDK.h"

@implementation UIControl (CCAutoTrack)

+ (void)load {
//    [UIControl cc_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(cc_didMoveToSuperview)];
}

- (void)cc_didMoveToSuperview {
    // 调用原始方法实现
    [self cc_didMoveToSuperview];
    
    // 添加类型为UIControlEventTouchDown的一组Target-Action
    [self addTarget:self action:@selector(cc_touchDownAction:event:) forControlEvents:UIControlEventTouchDown];
}

- (void)cc_touchDownAction:(UIControl *)sender event:(UIEvent *)event {
    if ([self cc_isAddMultipleTargetAction]) {
        // 触发$AppClick
        [[CCAutoTrackSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
}

- (BOOL)cc_isAddMultipleTargetAction {
    
    // 如果有多target，说明除了添加的target，还有其他
    // 那么返回YES，触发$AppClick
    if (self.allTargets.count >= 2) {
        return YES;
    }
    
    // 如果控件本身为 Target 对象，并且添加除了 UIControlEventTouchDown 类型的 Action 方法
    // 说明开发者以本身为 Target 对象，添加了多个 Action 方法
    // 那么返回 YES 触发$AppClick 事件
    if ((self.allControlEvents & UIControlEventAllEvents) != UIControlEventTouchDown) {
        return YES;
    }
    
    // 如果控件本身为 Target 对象，并添加了两个以上的 UIControlEventTouchDown 类型的 Action 方法
    // 那说明开发者自行添加了Actions 方法
    // 所以返回 YES 触发$AppClick 事件
    if ([self actionsForTarget:self forControlEvent:UIControlEventTouchDown].count >= 2) {
        return YES;
    }
    
    return NO;
}

@end

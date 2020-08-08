//
//  UIGestureRecognizer+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/31.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIGestureRecognizer+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackSDK.h"

@implementation UITapGestureRecognizer (CCAutoTrack)

+ (void)load {
    [UITapGestureRecognizer cc_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(cc_initWithTarget:action:)];
    [UITapGestureRecognizer cc_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(cc_addTarget:action:)];
}

- (instancetype)cc_initWithTarget:(id)target action:(SEL)action {
    // 调用原始方法
    [self cc_initWithTarget:target action:action];
    // 新增Target-Action，用于触发$AppClick事件
    // 这里其实调用的是 cc_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)cc_addTarget:(id)target action:(SEL)action {
    // 调用原始方法
    [self cc_addTarget:target action:action];
    // 新增Target-Action，用于触发$AppClick事件
    [self cc_addTarget:self action:@selector(cc_trackTapGestureAction:)];
}

- (void)cc_trackTapGestureAction:(UITapGestureRecognizer *)sender {
    // 获取手势识别器的控件
    UIView *view = sender.view;
    
    // 只实现了UILabel和UIImageView，其他可自行拓展
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }
    
    // 触发$AppClick事件
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithView:view properties:nil];
}

@end

@implementation UILongPressGestureRecognizer (CCAutoTrack)

+ (void)load {
    [UILongPressGestureRecognizer cc_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(cc_initWithTarget:action:)];
    [UILongPressGestureRecognizer cc_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(cc_addTarget:action:)];
}

- (instancetype)cc_initWithTarget:(id)target action:(SEL)action {
    // 调用原始方法
    [self cc_initWithTarget:target action:action];
    // 新增Target-Action，用于触发$AppClick事件
    // 这里其实调用的是 cc_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)cc_addTarget:(id)target action:(SEL)action {
    // 调用原始方法
    [self cc_addTarget:target action:action];
    // 新增Target-Action，用于触发$AppClick事件
    [self cc_addTarget:self action:@selector(cc_trackLongPressGestureAction:)];
}

- (void)cc_trackLongPressGestureAction:(UILongPressGestureRecognizer *)sender {
    // 手势处于End时才触发$AppClick事件
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    // 获取手势识别器的控件
    UIView *view = sender.view;
    
    // 只实现了UILabel和UIImageView，其他可自行拓展
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }
    
    // 触发$AppClick事件
    [[CCAutoTrackSDK sharedInstance] trackAppClickWithView:view properties:nil];
}

@end

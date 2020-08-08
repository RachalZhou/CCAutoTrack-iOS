//
//  UIViewController+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIViewController+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackSDK.h"

static NSString * const kCCAutoTrackDataBlackListName = @"ccautotrack_black_list";

@implementation UIViewController (CCAutoTrack)

+ (void)load {
    [UIViewController cc_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(cc_viewDidAppear:)];
}

#pragma mark - Swizzle

- (void)cc_viewDidAppear:(BOOL)animated {
    // 调用原始方法
    [self cc_viewDidAppear:animated];
    
    if ([self shouldTrackAppViewScreen]) {
        // 触发$AppViewScreen事件
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
        
        // navigationItem.titleView的优先级高于navigationItem.title
        NSString *title = [self contentFromView:self.navigationItem.titleView];
        if (title.length == 0) {
            title = self.navigationItem.title;
        }
        [properties setValue:title forKey:@"title"];
        [[CCAutoTrackSDK sharedInstance] track:@"$AppViewScreen" properties:properties];
    }
}


#pragma mark - 黑名单

- (BOOL)shouldTrackAppViewScreen {
    static NSSet *blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 获取黑名单文件路径
        NSString *path = [[NSBundle bundleForClass:CCAutoTrackSDK.class] pathForResource:kCCAutoTrackDataBlackListName ofType:@"plist"];
        // 获取黑名单类名的数组
        NSArray *classNames = [NSArray arrayWithContentsOfFile:path];
        NSMutableSet *set = [NSMutableSet setWithCapacity:classNames.count];
        for (NSString *name in classNames) {
            [set addObject:NSClassFromString(name)];
        }
        blackList = [set copy];
    });
    
    for (Class cls in blackList) {
        // 判断当前类是否为黑名单中的类或者子类
        if ([self isKindOfClass:cls]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Title

- (NSString *)contentFromView:(UIView *)rootView {
    if (rootView.isHidden) {
        return nil;
    }
    
    NSMutableString *elementContent = [NSMutableString string];
    
    if ([rootView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)rootView;
        NSString *title = button.titleLabel.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)rootView;
        NSString *title = label.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)rootView;
        NSString *title = textView.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subView in rootView.subviews) {
            NSString *title = [self contentFromView:subView];
            if (title.length > 0) {
                [elementContentArray addObject:title];
            }
        }
        
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }
    
    return [elementContent copy];
}

@end

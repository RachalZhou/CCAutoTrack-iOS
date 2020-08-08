//
//  UIView+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIView+CCAutoTrack.h"

@implementation UIView (CCAutoTrack)

- (NSString *)cc_elementType {
    return NSStringFromClass([self class]);
}

- (NSString *)cc_elementContent {
    // 如果是隐藏控件，不获取控件内容
    if (self.isHidden || self.alpha == 0) {
        return nil;
    }
    
    // 初始化数组，用于保存控件内容
    NSMutableArray *contents = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        NSString *content = view.cc_elementContent;
        if (content.length > 0) {
            [contents addObject:content];
        }
    }
    
    // 未取到内容返回nil，取到内容用"-"拼接
    return contents.count == 0 ? nil : [contents componentsJoinedByString:@"-"];
}

- (UIViewController *)cc_viewController {
    UIResponder *responder = self;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到，返回nil
    return nil;
}

@end

@implementation UIButton (CCAutoTrack)

- (NSString *)cc_elementContent {
    return self.currentTitle ?: super.cc_elementContent;
}

@end

@implementation UILabel (CCAutoTrack)

- (NSString *)cc_elementContent {
    return self.text ?: super.cc_elementContent;
}

@end

@implementation UISwitch (CCAutoTrack)

- (NSString *)cc_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UISlider (CCAutoTrack)

- (NSString *)cc_elementContent {
    return [NSString stringWithFormat:@"%.2f", self.value];
}

@end

@implementation UISegmentedControl (CCAutoTrack)

- (NSString *)cc_elementContent {
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIStepper (CCAutoTrack)

- (NSString *)cc_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

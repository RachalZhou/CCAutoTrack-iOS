//
//  UIApplication+CCAutoTrack.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "UIApplication+CCAutoTrack.h"
#import "NSObject+CCSwizzler.h"
#import "CCAutoTrackSDK.h"

@implementation UIApplication (CCAutoTrack)

+ (void)load {
    [UIApplication cc_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(cc_sendAction:to:from:forEvent:)];
}

- (BOOL)cc_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    if ([sender isKindOfClass:UISwitch.class] ||
        [sender isKindOfClass:UISegmentedControl.class] ||
        [sender isKindOfClass:UIStepper.class] ||
        event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        // 触发$AppClick
        [[CCAutoTrackSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
    
    // 调用原有实现
    return [self cc_sendAction:action to:target from:sender forEvent:event];
}

@end

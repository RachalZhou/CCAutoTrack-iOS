//
//  UIView+CCAutoTrack.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CCAutoTrack)

@property (nonatomic, copy, readonly) NSString *cc_elementType;
@property (nonatomic, copy, readonly) NSString *cc_elementContent;
@property (nonatomic, readonly) UIViewController *cc_viewController;

@end

#pragma mark - UIButton
@interface UIButton (CCAutoTrack)

@end

#pragma mark - UILabel
@interface UILabel (CCAutoTrack)

@end

#pragma mark - UISwitch
@interface UISwitch (CCAutoTrack)

@end

#pragma mark - UISlider
@interface UISlider (CCAutoTrack)

@end

#pragma mark - UISegmentedControl
@interface UISegmentedControl (CCAutoTrack)

@end

#pragma mark - UIStepper
@interface UIStepper (CCAutoTrack)

@end

NS_ASSUME_NONNULL_END

//
//  UIScrollView+CCAutoTrack.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCAutoTrackDelegateProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (CCAutoTrack)

@property (nonatomic, strong, nullable) CCAutoTrackDelegateProxy *cc_delegateProxy;

@end

NS_ASSUME_NONNULL_END

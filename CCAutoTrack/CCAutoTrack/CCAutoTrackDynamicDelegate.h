//
//  CCAutoTrackDynamicDelegate.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackDynamicDelegate : NSObject

+ (void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

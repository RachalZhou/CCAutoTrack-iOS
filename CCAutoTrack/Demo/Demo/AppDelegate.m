//
//  AppDelegate.m
//  Demo
//
//  Created by 周日朝 on 2020/7/28.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "AppDelegate.h"
#import <CCAutoTrack/CCAutoTrack.h>

@interface AppDelegate ()


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 初始化埋点SDK
    [CCAutoTrackSDK startWithServerURL:@"www.jneg.com"];
    [[CCAutoTrackSDK sharedInstance] login:@"123456789"];
    return YES;
}

@end

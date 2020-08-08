//
//  CCAutoTrackReleaseObject.m
//  Demo
//
//  Created by 周日朝 on 2020/8/3.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackReleaseObject.h"

@implementation CCAutoTrackReleaseObject

- (void)signalCrash {
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] init];
    [array addObject:@"First"];
    [array release];
    NSLog(@"Crash: %@", array.firstObject);
}

@end

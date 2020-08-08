//
//  CCAutoTrackNetwork.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/2.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackNetwork : NSObject

/// 数据上报的服务器地址
@property (nonatomic, strong) NSURL *serverURL;

/// 禁止直接使用init方法进行初始化
- (instancetype)init NS_UNAVAILABLE;

/// @abstract 指定初始化方法
/// @param serverURL 服务器URL地址
/// @return 初始化对象
- (instancetype)initWithServerURL:(NSURL *)serverURL NS_DESIGNATED_INITIALIZER;

/// @abstract 同步事件
/// @param events 事件数组
/// @return 是否同步成功
- (BOOL)flushEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END

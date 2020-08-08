//
//  CCAutoTrackFileStore.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/1.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackFileStore : NSObject

/// 文件缓存路径
@property (nonatomic, copy) NSString *filePath;

/// 所有事件
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *allEvents;

/// 最大本地事件数量
@property (nonatomic) NSUInteger maxLocalEventCount;

/// @abstract 将事件保存到文件中
/// @param event 事件数据
- (void)saveEvent:(NSDictionary *)event;

/// @abstract 根据数量删除本地保存的数据
/// @param count 需要删除的事件数量
- (void)deleteEventsForCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END

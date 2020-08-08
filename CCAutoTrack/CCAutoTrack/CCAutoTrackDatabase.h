//
//  CCAutoTrackDatabase.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/1.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackDatabase : NSObject

/// 数据库缓存路径
@property (nonatomic, copy, readonly) NSString *filePath;

/// sqlite3数据库
@property (nonatomic) sqlite3 *database;

/// 本地事件存储总量
@property (nonatomic) NSUInteger eventCount;

/// @abstract 初始化方法
/// @param filePath 数据库路径，如果为nil，使用默认路径
/// @return 数据库对象
- (instancetype)initWithFilePath:(nullable NSString *)filePath NS_DESIGNATED_INITIALIZER;

/// @abstract 向数据库中插入事件数据
/// @param event 事件
- (void)insertEvent:(NSDictionary *)event;

/// @abstract 从数据库中获取事件数据
/// @param count 获取事件数据的条数
/// @return 事件数据
- (NSArray<NSString *> *)selectEventsForCount:(NSUInteger)count;

/// @abstract 从数据库中删除一定数量的事件数据
/// @param count 需要删除事件数据的条数
/// @return 是否成功删除数据
- (BOOL)deleteEventsForCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END

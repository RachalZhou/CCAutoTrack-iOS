//
//  CCAutoTrackSDK.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/28.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackSDK : NSObject

/// 设备ID（匿名ID）
@property (nonatomic, copy) NSString *anonymousId;

/// 当本地缓存的事件达到最大条数时，上传数据（默认为100条）
@property (nonatomic) NSUInteger flushBulkSize;

/// 两次数据发送的时间间隔，单位为秒
@property (nonatomic) NSUInteger flushInterval;

- (instancetype)init NS_UNAVAILABLE;

/// @abstract 初始化SDK
/// @param urlString 接收数据的服务端URL
+ (void)startWithServerURL:(NSString *)urlString;

/// @abstract 获取SDK单例
/// @return 返回单例
+ (CCAutoTrackSDK *)sharedInstance;

/// @abstract 用户登录，设置登录ID
/// @param loginId 用户的登录ID
- (void)login:(NSString *)loginId;

/// @abstract 向服务器同步本地所有数据
- (void)flush;

@end

#pragma mark - Track
@interface CCAutoTrackSDK (Track)

/// @abstract 调用Track接口，触发事件
/// @discussion properties是一个NSDictionary，其中key是属性的名，必须是NSString类型，value是属性的内容
/// @param eventName 事件名称
/// @param properties 事件属性
- (void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *, id> *)properties;

/// @abstract 触发$AppClick事件
/// @param view 触发事件的控件
/// @param properties 自定义事件属性
- (void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *, id> *)properties;

/// @abstract 支持UITableView触发$AppClick事件
/// @param tableView 触发事件的UITableView视图
/// @param indexPath 在UITableView中的位置
/// @param properties 自定义事件属性
- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties;

/// @abstract 支持UICollectionView触发$AppClick事件
/// @param collectionView 触发事件的UICollectionView视图
/// @param indexPath 在UICollectionView中的位置
/// @param properties 自定义事件属性
- (void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties;

@end

#pragma mark - Timer

@interface CCAutoTrackSDK (Timer)

/// @abstract 开始统计事件时长
/// @param event 事件名
- (void)trackTimerStart:(NSString *)event;

/// @abstract 暂停统计事件时长
/// @param event 事件名
- (void)trackTimerPause:(NSString *)event;

/// @abstract 继续统计事件时长
/// @param event 事件名
- (void)trackTimerResume:(NSString *)event;

/// @abstract结束事件时长统计，计算时长
/// @discussion 事件时长从调用-trackTimerStart:开始，一直到调用-trackTimerEnd:properties:方法结束。如果多次调用-trackTimerStart:，则从最后一次计算；如果没用调用-trackTimerStart，就直接调用-trackTimerEnd:properties:方法，则触发一次普通事件，不带时长属性。
/// @param event 事件名，与开始时事件名一致
/// @param propedrties 事件属性
- (void)trackTimerEnd:(NSString *)event properties:(nullable NSDictionary<NSString *, id> *)propedrties;

@end

NS_ASSUME_NONNULL_END

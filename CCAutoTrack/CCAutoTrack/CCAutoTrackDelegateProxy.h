//
//  CCAutoTrackDelegateProxy.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/30.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAutoTrackDelegateProxy : NSProxy<UITableViewDelegate, UICollectionViewDelegate>

/// 初始化委托对象，用于拦截UITableView控件的选中cell事件
/// @param delegate UITableView控件的代理
/// @return 初始化对象
+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

/// 初始化委托对象，用于拦截UICollectionView控件的选中cell事件
/// @param delegate UICollectionView控件的代理
/// @return 初始化对象
+ (instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

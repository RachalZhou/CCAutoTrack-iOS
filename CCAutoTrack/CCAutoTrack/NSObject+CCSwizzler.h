//
//  NSObject+CCSwizzler.h
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/29.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CCSwizzler)

/// @abstract 交换方法名为originalSEL和方法名为alternateSEL两个方法的实现
/// @param originalSEL 原始方法名称
/// @param alternateSEL 要交换的方法名称
+ (BOOL)cc_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL;

@end

NS_ASSUME_NONNULL_END

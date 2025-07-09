//
//  GViewScrollPager.h
//  GPageKit
//
//  Created by GIKI on 2019/10/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GBaseScrollPager.h"

NS_ASSUME_NONNULL_BEGIN

@interface GViewScrollPager : GBaseScrollPager

/// return a recycled pager
- (nullable __kindof UIView *)dequeueReusablePager;

/// return a recycled pager by identifier
- (nullable __kindof UIView *)dequeueReusablePagerForIdentifier:(NSString *)identifier;

/// The currently visible primary view on screen. Can be a page or accessories.
- (nullable __kindof UIView *)visiblePager;

/// return a recycled pager with pageindex
- (nullable __kindof UIView *)pagerForIndex:(NSInteger)pageIndex;
@end

NS_ASSUME_NONNULL_END

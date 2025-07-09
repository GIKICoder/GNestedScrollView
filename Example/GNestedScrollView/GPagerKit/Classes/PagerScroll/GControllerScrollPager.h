//
//  GControllerScrollPager.h
//  GPageKit
//
//  Created by GIKI on 2019/10/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GBaseScrollPager.h"

NS_ASSUME_NONNULL_BEGIN

@interface GControllerScrollPager : GBaseScrollPager

@property (nonatomic, weak  ) UIViewController  * targetController;

/// return a recycled pager
- (nullable __kindof UIViewController *)dequeueReusablePager;

/// return a recycled pager by identifier
- (nullable __kindof UIViewController *)dequeueReusablePagerForIdentifier:(NSString *)identifier;

/// The currently visible primary view on screen. Can be a page or accessories.
- (nullable __kindof UIViewController *)visiblePager;

/// return a recycled pager with pageindex
- (nullable __kindof UIViewController *)pagerForIndex:(NSInteger)pageIndex;

@end

NS_ASSUME_NONNULL_END

//
//  GViewScrollPager.m
//  GPageKit
//
//  Created by GIKI on 2019/10/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GViewScrollPager.h"

@implementation GViewScrollPager


/// return a recycled pager
- (nullable __kindof UIView *)dequeueReusablePager
{
    return [super dequeueReusablePager];
}

/// return a recycled pager by identifier
- (nullable __kindof UIView *)dequeueReusablePagerForIdentifier:(NSString *)identifier
{
    return [super dequeueReusablePagerForIdentifier:identifier];
}

/// The currently visible primary view on screen. Can be a page or accessories.
- (nullable __kindof UIView *)visiblePager
{
    return [super visiblePager];
}

/// return a recycled pager with pageindex
- (nullable __kindof UIView *)pagerForIndex:(NSInteger)pageIndex
{
    UIView * view = [super pagerForIndex:pageIndex];
    if ([view isKindOfClass:UIView.class]) {
        return view;
    }
    return nil;
}

#pragma mark - Internal Method

- (void)__addSubview:(UIView *)pager target:(UIView *)target
{
    if (![pager isKindOfClass:UIView.class]) {
        return;
    }
    [target addSubview:pager];
}

- (void)__setPager:(UIView *)pager Frame:(CGRect)rect
{
    if (![pager isKindOfClass:UIView.class]) {
        return;
    }
    pager.frame = rect;
}

- (void)__removeFromSuperview:(UIView *)pager
{
    if (![pager isKindOfClass:UIView.class]) {
        return;
    }
    if (pager.superview) {
        [pager removeFromSuperview];
    }
}

- (__kindof id)__constructPager:(Class)clazz identifier:(NSString *)identifier
{
    UIView * pager = [[clazz alloc] initWithFrame:self.bounds];
    pager.pageIdentifier = identifier;
    return pager;
}

@end

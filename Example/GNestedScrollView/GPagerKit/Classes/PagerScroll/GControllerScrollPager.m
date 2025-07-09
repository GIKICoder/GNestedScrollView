//
//  GControllerScrollPager.m
//  GPageKit
//
//  Created by GIKI on 2019/10/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GControllerScrollPager.h"

@implementation GControllerScrollPager

/// return a recycled pager
- (nullable __kindof UIViewController *)dequeueReusablePager
{
    UIViewController * vc = [super dequeueReusablePager];
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

/// return a recycled pager by identifier
- (nullable __kindof UIViewController *)dequeueReusablePagerForIdentifier:(NSString *)identifier
{
    UIViewController * vc = [super dequeueReusablePagerForIdentifier:identifier];
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

/// The currently visible primary view on screen. Can be a page or accessories.
- (nullable __kindof UIViewController *)visiblePager
{
    UIViewController * vc = [super visiblePager];
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

/// return a recycled pager with pageindex
- (nullable __kindof UIViewController *)pagerForIndex:(NSInteger)pageIndex
{
    UIViewController * vc = [super pagerForIndex:pageIndex];
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

#pragma mark - Internal Method

- (void)__addSubview:(UIViewController *)pager target:(UIView *)target
{
    if (![pager isKindOfClass:UIViewController.class]) {
        return;
    }
    if ([target.subviews containsObject:pager.view]) {
        pager.view.hidden = NO;
        return;
    }
    [target addSubview:pager.view];
}

- (void)__setPager:(UIViewController *)pager Frame:(CGRect)rect
{
    if (![pager isKindOfClass:UIViewController.class]) {
        return;
    }
    pager.view.frame = rect;
}

- (void)__removeFromSuperview:(UIViewController *)pager
{
    if (![pager isKindOfClass:UIViewController.class]) {
        return;
    }
    
    if (pager.view.superview) {
        pager.view.hidden = YES;
//        [pager.view removeFromSuperview];
    }
}

- (__kindof id)__constructPager:(Class)clazz identifier:(NSString *)identifier
{
    UIViewController * vc = [[clazz alloc] init];
    vc.pageIdentifier = identifier;
    [self.targetController addChildViewController:vc];
    [vc didMoveToParentViewController:self.targetController];
    return vc;
}

- (UIViewController *)targetController
{
    if (!_targetController) {
        _targetController = [self currentViewController];
    }
    return _targetController;
}

- (UIViewController *)currentViewController
{
    UIViewController * vc = nil;
    for (UIView * next = [self superview]; next; next = next.superview) {
        __kindof UIResponder * nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:UIViewController.class]) {
            vc = nextResponder;
            break;
        }
    }
    return vc;
}
@end

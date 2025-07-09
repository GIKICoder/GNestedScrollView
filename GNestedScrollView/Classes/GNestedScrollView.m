//
//  GStackScrollView.m
//  GStackScrollView
//
//  Created by GIKI on 2024/8/5.
//

#import "GNestedScrollView.h"
#import "NSObject+GFBKVOController.h"

@interface GNestedScrollView ()<UIScrollViewDelegate>
@property (nonatomic, strong) NSPointerArray * containers;
@property (nonatomic, strong) UIScrollView * overlayView;
@property (nonatomic, strong) NSPointerArray * childScollViews;
@property (nonatomic, strong) NSMapTable * childScollViewsMap;
@property (nonatomic, strong) UIImageView * stretchView;
@property (nonatomic, assign) CGRect  originalRect;
@property (nonatomic, assign) BOOL  isHover;
@end

@implementation GNestedScrollView

#pragma mark - Init Method

- (instancetype)init
{
    return [self initWithStackContainers:@[]];
}

- (instancetype)initWithStackContainers:(NSArray *)containers
{
    self = [super init];
    if (self) {
        self.showsVerticalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        self.scrollsToTop = NO;
        self.childScrollPullWhenBounces = YES;
        self.childScollViewsMap = [NSMapTable weakToStrongObjectsMapTable];
        self.childScollViews = [NSPointerArray weakObjectsPointerArray];
        self.containers = [NSPointerArray weakObjectsPointerArray];
        for (id co in containers) {
            [self.containers addPointer:(__bridge void *)co];
        }
        [self __setNeedsUpdateContainer];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (self.overlayView.superview) {
        [self.overlayView removeFromSuperview];
    }
    if (!newSuperview) {
        /// remove from superView
        return;
    }
    [newSuperview insertSubview:self.overlayView belowSubview:self];
    [self addGestureRecognizer:self.overlayView.panGestureRecognizer];
    [self addSubview:self.stretchView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.frame, self.overlayView.frame)) {
        self.overlayView.frame = self.frame;
    }
}

- (UIScrollView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[UIScrollView alloc] init];
        _overlayView.frame = self.frame;
//        _overlayView.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.5];
        _overlayView.delegate = self;
        _overlayView.alwaysBounceVertical = YES;
        _overlayView.layer.zPosition = CGFLOAT_MAX;
        if (@available(iOS 11.0, *)) {
            _overlayView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    return _overlayView;
}

- (UIImageView *)stretchView
{
    if (!_stretchView) {
        _stretchView = [[UIImageView alloc] init];
        _stretchView.backgroundColor = UIColor.clearColor;
        _stretchView.contentMode = UIViewContentModeScaleAspectFill;
        _stretchView.clipsToBounds = YES;
    }
    return _stretchView;
}

#pragma mark - Public Method

- (void)addContainer:(id)container
{
    if (!container) return;
    [self.containers addPointer:(__bridge void *)container];
    [self __setNeedsUpdateContainer];
}

- (void)insertContainer:(id)container atIndex:(NSInteger)index
{
    if (!container) return;
    if (index >= self.containers.count) {
        [self addContainer:container];
        return;
    }
    [self.containers insertPointer:(__bridge void *)container
                           atIndex:index];
    [self __setNeedsUpdateContainer];
}

- (void)addContainer:(id)container before:(id)before
{
    NSUInteger index = [self indexOfContainer:before];
    if (index == NSNotFound){
        index = self.containers.count;
    }
    [self insertContainer:container atIndex:index];
}

- (void)addContainer:(id)container after:(id)after
{
    NSUInteger index = [self indexOfContainer:after];
    if (index == NSNotFound){
        index = 0;
    } else {
        index += 1;
    }
    [self insertContainer:container atIndex:index];
}

- (void)removeContainer:(id)container
{
    NSUInteger index = [self indexOfContainer:container];
    if (index != NSNotFound && index < self.containers.count)
        [self.containers removePointerAtIndex:index];
    [self.containers compact];
    UIView * attachView = [self __fetchAttachViewWithContainer:container];
    if (attachView && attachView.superview) {
        [attachView removeFromSuperview];
    }
    [self __setNeedsUpdateContainer];
}

/// 是否添加了container
/// - Parameter container: <#container description#>
- (BOOL)containWithContainer:(id)container
{
    return [self.allContainers containsObject:container];
}

- (void)removeAllContainers
{
    for (NSUInteger i = self.containers.count; i > 0; i -= 1) {
        NSArray * array = self.containers.allObjects;
        [array enumerateObjectsUsingBlock:^(id  _Nonnull container, NSUInteger idx, BOOL * _Nonnull stop) {

            UIView * attachView = [self __fetchAttachViewWithContainer:container];
            if (attachView && attachView.superview) {
                [attachView removeFromSuperview];
            }
        }];
        [self.containers removePointerAtIndex:i - 1];
    }
    [self __setNeedsUpdateContainer];
}

/// 获取所有的container
- (NSArray *)allContainers
{
    return [self.containers allObjects];
}

- (id)lastContainer
{
    return [self.containers allObjects].lastObject;
}

/// 第一个container
- (id)firstContainer
{
    return [self.containers allObjects].firstObject;
}

/// 滚动到对应的container
/// @param container <#container description#>
/// @param animated <#animation description#>
- (void)scrollToContainer:(id)container animated:(BOOL)animated
{
    UIView * attachView = [self __fetchAttachViewWithContainer:container];
    if (!attachView) {
        return;
    }
    [self.overlayView setContentOffset:CGPointMake(self.contentOffset.x, attachView.frame.origin.y) animated:animated];
}

/// 滚动到顶部
- (void)scrollToTopContainer:(BOOL)animated
{
    [self.overlayView setContentOffset:CGPointZero animated:animated];
}

/// 添加子child scrollView 监听.
/// @param scrollView scrollView description
/// @brief 一般用于多层横向嵌套的竖向child scrollView.
- (void)addObserverStackChildScrollView:(__kindof UIScrollView *)scrollView
{
    if (!scrollView || ![scrollView isKindOfClass:UIScrollView.class] || [self.childScollViews.allObjects containsObject:scrollView]) {
        return;
    }
    [self.childScollViewsMap setObject:@(0) forKey:scrollView];
    [self.childScollViews addPointer:(__bridge void *)scrollView];
    __weak typeof(self) weakSelf = self;
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.overlayView.panGestureRecognizer];
    [self.KVOController observe:scrollView keyPath:@"contentSize" options:options block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        CGSize newSize = CGSizeZero;
        CGSize oldSize = CGSizeZero;
        id newValue = [change valueForKey:NSKeyValueChangeNewKey];
        [(NSValue*)newValue getValue:&newSize];
        id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
        [(NSValue*)oldValue getValue:&oldSize];
        if (!CGSizeEqualToSize(newSize, oldSize)) {
            [weakSelf __updateStackOverlayContentSize];
        }
    }];
}

- (void)updateStackOverlayContentSize
{
    CGFloat top_origin = 0;
    NSNumber * offsetN = nil;
    for (id container  in self.containers) {
        
        UIView * attachView = [self __fetchAttachViewWithContainer:container];
        if (!attachView) {continue;}
        UIScrollView * adjust_scrollView = [self __fetchAdjustScrollerWithContainer:container];
        NSNumber * _offsetN = [self.childScollViewsMap objectForKey:adjust_scrollView];
        if (_offsetN) {
            offsetN = _offsetN;
        }
        if (adjust_scrollView) {
            CGFloat contentHeight = adjust_scrollView.contentSize.height+adjust_scrollView.contentInset.top+adjust_scrollView.contentInset.bottom;
            top_origin += MAX(contentHeight, adjust_scrollView.frame.size.height);
        } else {
            top_origin += attachView.frame.size.height;
        }
    }
    
    if (self.overlayView) {
        self.overlayView.contentSize = CGSizeMake(self.contentSize.width, top_origin);
        if (offsetN) {
            CGFloat offset = [offsetN floatValue];
            if (offset <= 0) {
                offset = [self __fetchHoverHeight];
            }
            if (self.isHover) {
                [self.overlayView setContentOffset:CGPointMake(self.overlayView.contentOffset.x, offset) animated:NO];
            }
        }
       
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedUpdateScrollContentSize:)]) {
        [self.nestedDelegate g_nestedUpdateScrollContentSize:CGSizeMake(self.contentSize.width, top_origin)];
    }
}

- (void)setNeedsUpdateContainer
{
    [self __setNeedsUpdateContainer];
}
#pragma mark - Private Method

- (NSUInteger)indexOfContainer:(id)container
{
    for (NSUInteger i = 0; i < self.containers.count; i += 1) {
        if ([self.containers pointerAtIndex:i] == (__bridge void*)container) {
            return i;
        }
    }
    return NSNotFound;
}

- (UIView *)__fetchAttachViewWithContainer:(id)container
{
    if (container && [container respondsToSelector:@selector(g_nestedAttatchView)]) {
        return [container g_nestedAttatchView];
    } else if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedAttatchViewWithContainer:)]) {
        UIView * attach = [self.nestedDelegate g_nestedAttatchViewWithContainer:container];
        if (attach) {
            return attach;
        }
    }
    if (container && [container isKindOfClass:UIView.class]) {
        return (id)container;
    }
    return nil;
}

- (UIScrollView *)__fetchAdjustScrollerWithContainer:(id)container
{
    if (container && [container respondsToSelector:@selector(g_nestedScrollView)]) {
        UIScrollView * scrollView = [container g_nestedScrollView];
        if (scrollView && [scrollView isKindOfClass:UIScrollView.class]) {
            return scrollView;
        }
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedScrollViewWithContainer:)]) {
        UIScrollView * scrollView = [self.nestedDelegate g_nestedScrollViewWithContainer:container];
        if (scrollView && [scrollView isKindOfClass:UIScrollView.class]) {
            return scrollView;
        }
    }
    return nil;
}

- (CGFloat)__fetchCustomAttatchViewFrameWithContainer:(id)container
{
    if (container && [container respondsToSelector:@selector(g_customAttatchViewHeight)]) {
        return [container g_customAttatchViewHeight];
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_customAttatchViewHeight:)]) {
        CGFloat ret = [self.nestedDelegate g_customAttatchViewHeight:container];
        return ret;
    }
    return 0;
}

- (BOOL)__fetchNeedUpdateFrameWithContainer:(id)container
{
    if (container && [container respondsToSelector:@selector(g_needUpdateFrameWhenContentSizeChanged)]) {
        return [container g_needUpdateFrameWhenContentSizeChanged];
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_needUpdateFrameWhenContentSizeChanged:)]) {
        BOOL ret  = [self.nestedDelegate g_needUpdateFrameWhenContentSizeChanged:container];
        return ret;
    }
    return NO;
}

- (BOOL)__fetchNeedTakeOverPanGestureWithContainer:(id)container
{
    if (container && [container respondsToSelector:@selector(g_needTakeoverScrollPanGesture)]) {
        return [container g_needTakeoverScrollPanGesture];
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_needTakeoverScrollPanGesture:)]) {
        BOOL ret  = [self.nestedDelegate g_needTakeoverScrollPanGesture:container];
        return ret;
    }
    return NO;
}

- (CGFloat)__fetchTopContainerHeight
{
    CGFloat __innerHeight = 0;
    if (self.containers && self.containers.count > 0) {
        for (NSUInteger i = 0; i < self.containers.count-1; i += 1) {
            id container = [self.containers.allObjects objectAtIndex:i];
            UIView * view = [self __fetchAttachViewWithContainer:container];
            __innerHeight += view.frame.size.height;
        }
    }
    return __innerHeight;
}

- (CGFloat)__fetchHoverHeight
{
    CGFloat hoverHeight = 0;
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedHoverHeight)]) {
        hoverHeight = [self.nestedDelegate g_nestedHoverHeight];
    } else {
        hoverHeight = [self __fetchTopContainerHeight];
    }
    return hoverHeight;
}

- (void)__updateStretchHeader:(CGFloat)offset_y
{
    if (!self.need_stretch_header) {
        return;
    }
    if (offset_y >= 0) {
        self.stretchView.frame = CGRectMake(0, 0, self.stretchView.frame.size.width,  self.originalRect.size.height);
        return;
    }
    self.stretchView.frame = CGRectMake(0, offset_y, self.stretchView.frame.size.width,  self.originalRect.size.height-offset_y);
}

- (void)__setNeedsUpdateContainer
{
    CGFloat top_origin = 0;
    for (id container  in self.containers) {
            
        UIView * attachView = [self __fetchAttachViewWithContainer:container];
        if (!attachView) {continue;}
        if (!attachView.superview && ![self.subviews containsObject:attachView]) {
            [self addSubview:attachView];
            [self addObserver:container];
        }
        CGRect rect = attachView.frame;
        rect.origin.y = top_origin;
        attachView.frame = rect;
        top_origin = CGRectGetMaxY(attachView.frame);
        /// setup stretch header
        if (self.need_stretch_header && [self firstContainer] == container) {
            if (![self.subviews containsObject:self.stretchView]) {
                [self insertSubview:self.stretchView atIndex:0];
            }
            self.stretchView.frame = attachView.bounds;
            if (!CGRectEqualToRect(CGRectZero, self.stretchCustomFrame)) {
                self.stretchView.frame = self.stretchCustomFrame;
            }
            self.originalRect = self.stretchView.frame;
        }
    }
    self.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, top_origin);
    [self __updateStackOverlayContentSize];
}


- (void)__updateStackOverlayContentSize
{
    CGFloat top_origin = 0;
    for (id container  in self.containers) {
        
        UIView * attachView = [self __fetchAttachViewWithContainer:container];
        if (!attachView) {continue;}
        UIScrollView * adjust_scrollView = [self __fetchAdjustScrollerWithContainer:container];
        if (adjust_scrollView) {
            CGFloat contentHeight = adjust_scrollView.contentSize.height+adjust_scrollView.contentInset.top+adjust_scrollView.contentInset.bottom;
            top_origin += MAX(contentHeight, adjust_scrollView.frame.size.height);
        } else {
            top_origin += attachView.frame.size.height;
        }
    }
    
    if (self.overlayView) {
        self.overlayView.contentSize = CGSizeMake(self.contentSize.width, top_origin);
    }
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedUpdateScrollContentSize:)]) {
        [self.nestedDelegate g_nestedUpdateScrollContentSize:CGSizeMake(self.contentSize.width, top_origin)];
    }
}

- (void)addObserver:(id)container
{
    __weak typeof(self) weakSelf = self;
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    UIView * attachView = [self __fetchAttachViewWithContainer:container];
    if (attachView) {
        /// observe attachView frame update stackview contentsize
        [self.KVOController observe:attachView keyPaths:@[GFBKVOKeyPath(attachView.frame), GFBKVOKeyPath(attachView.bounds)] options:options block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            CGRect newRect = CGRectZero;
            CGRect oldRect = CGRectZero;
            id newValue = [change valueForKey:NSKeyValueChangeNewKey];
            [(NSValue*)newValue getValue:&newRect];
            id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
            [(NSValue*)oldValue getValue:&oldRect];
            if (!CGRectEqualToRect(newRect, oldRect)) {
                [weakSelf __setNeedsUpdateContainer];
            }
        }];
    }
    UIScrollView * adjust_scrollView = [self __fetchAdjustScrollerWithContainer:container];
    if (adjust_scrollView && [adjust_scrollView isKindOfClass:UIScrollView.class]) {
        adjust_scrollView.scrollsToTop = NO;
        BOOL takeOver = [self __fetchNeedTakeOverPanGestureWithContainer:container];
        if (takeOver) {
            [adjust_scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.overlayView.panGestureRecognizer];
        }
        [self.KVOController observe:adjust_scrollView keyPath:@"contentSize" options:options block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            CGSize newSize = CGSizeZero;
            CGSize oldSize = CGSizeZero;
            id newValue = [change valueForKey:NSKeyValueChangeNewKey];
            [(NSValue*)newValue getValue:&newSize];
            id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
            [(NSValue*)oldValue getValue:&oldSize];
            if (!CGSizeEqualToSize(newSize, oldSize)) {
                BOOL need = [weakSelf __fetchNeedUpdateFrameWithContainer:container];
                
                if (need) {
                    UIView * attachView = [weakSelf __fetchAttachViewWithContainer:container];
                    CGRect rect = attachView.frame;
                    rect.size = newSize;
                    attachView.frame = rect;
                } else {
                    CGFloat height = [weakSelf __fetchCustomAttatchViewFrameWithContainer:container];
                    if (height > 0) {
                        UIView * attachView = [weakSelf __fetchAttachViewWithContainer:container];
                        CGRect rect = attachView.frame;
                        rect.size = CGSizeMake(rect.size.width, height);
                        attachView.frame = rect;
                    }
                }
                [weakSelf __updateStackOverlayContentSize];
            }
        }];
    }
}


/// 重置接管手势
/// @param container <#container description#>
- (void)resetTakeOverPanGestureWithContainer:(id)container
{
    UIScrollView * adjust_scrollView = [self __fetchAdjustScrollerWithContainer:container];
    if (adjust_scrollView) {
        BOOL takeOver = [self __fetchNeedTakeOverPanGestureWithContainer:container];
        if (takeOver) {
            [adjust_scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.overlayView.panGestureRecognizer];
        } else {
            [adjust_scrollView.panGestureRecognizer requireGestureRecognizerToFail:nil];
        }
    }
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat hoverHeight = [self __fetchHoverHeight];
    
    CGFloat offset = scrollView.contentOffset.y;
    
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedUpdateScrollOffset:)]) {
        [self.nestedDelegate g_nestedUpdateScrollOffset:scrollView.contentOffset];
    }
    /// scrollView 开启bounces效果
    if (!self.bounces) {
        if (offset <= 0) {
            self.isHover = NO;
            self.contentOffset = CGPointZero;
            if (!self.childScrollPullWhenBounces) {
                return;
            }
            id container = [self lastContainer];
            UIScrollView * attach_scrollView = [self __fetchAdjustScrollerWithContainer:container];
            if (!attach_scrollView) {
                return;
            }
            self.overlayView.contentOffset = CGPointZero;
            self.overlayView.panGestureRecognizer.state = UIGestureRecognizerStateCancelled;
            return;
        }
    }
    /// update stretch Header
    [self __updateStretchHeader:scrollView.contentOffset.y];
    
    /// hover offset
    if (offset < hoverHeight) {
        self.isHover = NO;
        self.contentOffset = scrollView.contentOffset;
        id container = [self lastContainer];
        UIScrollView * attach_scrollView = [self __fetchAdjustScrollerWithContainer:container];
        if (!attach_scrollView) {
            return;
        }
        if ([self.childScollViewsMap objectForKey:attach_scrollView]) {
            [self.childScollViewsMap setObject:@(0) forKey:attach_scrollView];
        }
        attach_scrollView.contentOffset = CGPointZero;
        if (self.childScollViews.allObjects.count > 0) {
            [self.childScollViews.allObjects enumerateObjectsUsingBlock:^(UIScrollView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.contentOffset = CGPointZero;
                [self.childScollViewsMap setObject:@(0) forKey:obj];
            }];
        }
    } else {
        self.isHover = YES;
        self.contentOffset = CGPointMake(0, hoverHeight);
        id container = [self lastContainer];
        UIScrollView * attach_scrollView = [self __fetchAdjustScrollerWithContainer:container];
        if (!attach_scrollView) {
            return;
        }
        attach_scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y - self.contentOffset.y);
        if ([self.childScollViewsMap objectForKey:attach_scrollView]) {
            [self.childScollViewsMap setObject:@(scrollView.contentOffset.y) forKey:attach_scrollView];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedWillBeginDragging:)]) {
        [self.nestedDelegate g_nestedWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedDidEndDecelerating:)]) {
        [self.nestedDelegate g_nestedDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (self.nestedDelegate && [self.nestedDelegate respondsToSelector:@selector(g_nestedDidEndDragging:willDecelerate:)]) {
        [self.nestedDelegate g_nestedDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

@end

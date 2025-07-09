//
//  GBaseScrollPager.m
//  GPageKit
//
//  Created by GIKI on 2019/9/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GBaseScrollPager.h"

// Constant Definitions
static NSString * const kGPagerDefaultPageIdentifier = @"__GPagerDefaultPageIdentifier";

@interface GBaseScrollPager ()<CAAnimationDelegate> {
    struct {
        //dataSource flags
        unsigned int dataSourceNumberOfPages;
        unsigned int dataSourcePageForIndex;
        
        //delegate flags
        unsigned int delegateWillJumpToIndex;
        unsigned int delegateDidTurnToIndex;
        
    } _pageScrollViewFlags;
}

@property (nonatomic, strong, readwrite) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *pagerClasses;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id> *visiblePagers;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *recycledPageSets;

/* Works out how many slots this pager view has, including accessory views. */
@property (nonatomic, readonly) NSInteger numberOfPageSlots;

@end

@implementation GBaseScrollPager

#pragma mark - Init Method

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window) {
        [self reloadPageScrollView];
    }
}

- (void)dealloc
{
    [self cleanup];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //exit out if there's no content to display
    if (self.numberOfPages == 0) { return; }
    
    //disable the layout code since we'll be manually doing it here
    self.disablePageLayout = YES;
    
    //re-align the scroll view to our new bounds
    self.scrollView.frame           = [self frameForScrollView];
    self.scrollView.contentSize     = [self contentSizeForScrollView];
    self.scrollView.contentOffset   = [self contentOffsetForScrollViewAtIndex:self.scrollIndex];
    
    //resize any visible pages
    __weak typeof(self) weakSelf = self;
    [self.visiblePagers enumerateKeysAndObjectsUsingBlock:^(NSNumber *pageNumber, id page, BOOL *stop) {
        CGRect rect = [weakSelf frameForViewAtIndex:pageNumber.unsignedIntegerValue];
        [weakSelf __setPager:page Frame:rect];
    }];

    //re-enable the layout code
    self.disablePageLayout = NO;
}


#pragma mark - setup

- (void)setup
{
    // Default view properties
    self.autoresizingMask       = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.clipsToBounds          = YES;
    self.backgroundColor        = [UIColor clearColor];
    
    // Default layout properties
    self.pageSpacing            = 0.0f;
    self.pageScrollDirection    = GPageDirectionTurnRight;
    
    // Create the main scroll view
    self.scrollView                                 = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.pagingEnabled                   = YES;
    self.scrollView.showsHorizontalScrollIndicator  = NO;
    self.scrollView.showsVerticalScrollIndicator    = NO;
    self.scrollView.bouncesZoom                     = NO;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior  = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:self.scrollView];
    
    // Create an observer to monitor when the scroll view offset changes or if a parent controller tries to change
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    [self.scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)cleanup
{
    //remove any currently visible pages from the view
    for (NSNumber *pageIndex in self.visiblePagers.allKeys) {
        id pager = self.visiblePagers[pageIndex];
        [self __removeFromSuperview:pager];
    }
    
    //clean up the page stores
    self.visiblePagers = nil;
    self.recycledPageSets = nil;
    
    //remove the scroll view observer
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"contentInset"];
}

#pragma mark - Observe Method

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self layoutPages];
        return;
    }
    
    if ([keyPath isEqualToString:@"contentInset"]) {
        [self resetScrollViewVerticalContentInset];
        return;
    }
}

- (NSMutableDictionary<NSString *,NSValue *> *)pagerClasses
{
    if (!_pagerClasses) {
        _pagerClasses = [[NSMutableDictionary alloc] init];
    }
    return _pagerClasses;
}

- (NSMutableDictionary<NSNumber *,id> *)visiblePagers
{
    if (!_visiblePagers) {
        _visiblePagers = [[NSMutableDictionary alloc] init];
    }
    return _visiblePagers;
}

- (NSMutableDictionary<NSString *, NSMutableSet *> *)recycledPageSets
{
    if (!_recycledPageSets) {
        _recycledPageSets = [[NSMutableDictionary alloc] init];
    }
    return _recycledPageSets;
}
#pragma mark - Public Method

- (void)reloadPageScrollView
{
    if (!self.dataSource) {
        return;
    }
    //start getting information from the data source
    self.numberOfPages = 0;
    if (_pageScrollViewFlags.dataSourceNumberOfPages) {
        self.numberOfPages = [self.dataSource numberOfPagesInPagerView:self];
    }
    /// set scrollview configure
    self.scrollView.frame = [self frameForScrollView];
    self.scrollView.contentSize = [self contentSizeForScrollView];
    self.scrollView.contentOffset = [self contentOffsetForScrollViewAtIndex:self.scrollIndex];
    
    //reset the pages
    [self resetPageLayout];
}

- (void)registerPagerClass:(Class)pagerClass
{
    NSString *identifier = kGPagerDefaultPageIdentifier;
    if ([pagerClass respondsToSelector:@selector(pageIdentifier)]) {
        NSString * temp = [pagerClass pageIdentifier];
        if (temp && temp.length > 0) {
            identifier = temp;
        }
    }
    
    NSValue *encodedStruct = [NSValue valueWithBytes:&pagerClass objCType:@encode(Class)];
    self.pagerClasses[identifier] = encodedStruct;
}

- (void)registerPagerClass:(Class)pagerClass identifier:(NSString *)identifier
{
    NSString *identifier_new = kGPagerDefaultPageIdentifier;
    if ([pagerClass respondsToSelector:@selector(pageIdentifier)]) {
        NSString * temp = [pagerClass pageIdentifier];
        if (temp && temp.length > 0) {
            identifier_new = temp;
        }
    }
    if (identifier && identifier.length > 0) {
        identifier_new = identifier;
    }
    NSValue *encodedStruct = [NSValue valueWithBytes:&pagerClass objCType:@encode(Class)];
    self.pagerClasses[identifier_new] = encodedStruct;
}

- (nullable __kindof id)dequeueReusablePager
{
    return [self dequeueReusablePagerForIdentifier:kGPagerDefaultPageIdentifier];
}

- (nullable __kindof id)dequeueReusablePagerForIdentifier:(NSString *)identifier
{
    NSMutableSet *recycledPagesSet = self.recycledPageSets[identifier];
    id pager = recycledPagesSet.anyObject;
    
    if (pager) {
        [self __setPager:pager Frame:self.bounds];
        [recycledPagesSet removeObject:pager];
    } else if (self.pagerClasses[identifier]) {
        Class pageClass;
        [self.pagerClasses[identifier] getValue:&pageClass];
        pager = [self __constructPager:pageClass identifier:identifier];
        [self __setPager:pager Frame:self.bounds];
    }
    return pager;
}

- (nullable __kindof id)visiblePager
{
    return [self pagerForIndex:self.pageIndex];
}

- (nullable __kindof UIView *)visiblePageView
{
    return [self pagerForIndex:self.pageIndex];
}

- (nullable __kindof id)pagerForIndex:(NSInteger)pageIndex
{
    // Return page
    id page = [self.visiblePagers objectForKey:@(pageIndex)];
    return page;
}

/** Page Navigation Checking */
- (BOOL)canGoForward
{
    return self.scrollIndex > 0;
}

- (BOOL)canGoBack
{
    return self.scrollIndex < self.numberOfPageSlots-1;
}

- (void)turnToNextPageAnimated:(BOOL)animated
{
    if ([self canGoForward] == NO) {
        return;
    }
    
    NSInteger index = self.scrollIndex;
    
    [self turnToPageAtIndex:index+1 animated:animated];
}

- (void)turnToPreviousPageAnimated:(BOOL)animated
{
    if ([self canGoBack] == NO) {
        return;
    }
    
    NSInteger index = self.scrollIndex;
    [self turnToPageAtIndex:index-1 animated:animated];
}

- (void)turnToPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = MAX(0, index);
    index = MIN(self.numberOfPages-1, index);

    // Inform the delegate
    if (_pageScrollViewFlags.delegateWillJumpToIndex) {
        [self.delegate pagerView:self willJumpToPageAtIndex:index];
    }
    
    // If not animated, just change the offset and relayout
    if (animated == NO) {
        self.scrollView.contentOffset = [self contentOffsetForScrollViewAtIndex:index];
        [self layoutPages];
        return;
    }
    
    // Kill any existing animations
    [self.scrollView.layer removeAllAnimations];
    
    // Re-enable layouts after the animation has been killed so we can update the current state
    self.disablePageLayout = NO;
    [self layoutPages];
    
    self.disablePageLayout = YES;
    
    if (labs(index - self.scrollIndex) > 1) {
        id page = [self visiblePager];
        NSInteger newIndex = 0;
        if (index > self.scrollIndex) {
            newIndex = index - 1;
        }
        else {
            newIndex = index + 1;
        }
        
        //jump to the position just before
        [UIView performWithoutAnimation:^{
            CGRect rect = [self frameForViewAtIndex:newIndex];
            [self __setPager:page Frame:rect];
            self.scrollView.contentOffset = [self contentOffsetForScrollViewAtIndex:newIndex];
        }];
    }
    
    // Update the scroll index to match the new value
    self.scrollIndex = index;
    
    // Layout the target cell
    [self layoutViewAtScrollIndex:index];
    
    // Trigger the did move to page index delegate
    if (_pageScrollViewFlags.delegateDidTurnToIndex) {
        [self.delegate pagerView:self didTurnToPageAtIndex:self.pageIndex];
    }
    
    // Set up the animation block
    id animationBlock = ^{
        self.scrollView.contentOffset = [self contentOffsetForScrollViewAtIndex:index];
    };
    
    // Set up the completion block
    void (^completionBlock)(BOOL complete) = ^(BOOL complete) {
        // Don't relayout if we intentionally killed the animation
        if (complete == NO) { return; }
        
        //re-enable the page layout and perform a refresh
        self.disablePageLayout = NO;
        [self layoutPages];
        
        // Inform the scroll view delegate (if there is one) that the scrolling animation completed
        if (self.scrollView.delegate && [self.scrollView.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
            [self.scrollView.delegate scrollViewDidEndScrollingAnimation:self.scrollView];
        }
    };
    if (animated) {
        // Perform the animation
        [UIView animateWithDuration:0.35f
                              delay:0.0f
             usingSpringWithDamping:1.0f
              initialSpringVelocity:0.3f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        if (completionBlock) {
            completionBlock(YES);
        }
    }

}

#pragma mark - Private Method

- (void)resetPageLayout
{
    [self.visiblePagers enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, id  page, BOOL *stop) {
        [self __removeFromSuperview:page];
        [[self recycledPagesSetForPage:page] addObject:page];
    }];
    [self.visiblePagers removeAllObjects];

    // Perform relayout calculation
    [self layoutPages];
    
    // Inform the delegate on first run
    if (_pageScrollViewFlags.delegateDidTurnToIndex) {
        [self.delegate pagerView:self didTurnToPageAtIndex:self.pageIndex];
    }
}

- (void)layoutPages
{
    if (self.disablePageLayout || self.numberOfPages == 0) {
        return;
    }
    //Determine which pages are currently visible on screen
    CGPoint contentOffset       = self.scrollView.contentOffset;
    CGFloat scrollViewWidth     = self.scrollView.bounds.size.width;
    
    //Work out the number of slots the scroll view has (eg, pages + accessories)
    NSInteger numberOfPageSlots = self.numberOfPageSlots;
    
    //Determine the origin page on the far left
    NSRange visiblePagesRange   = NSMakeRange(0, 1);
    visiblePagesRange.location  = MAX(0, floor(contentOffset.x / scrollViewWidth));
    
    //Based on the delta between the offset of that page from the current offset, determine if the page after it is visible
    CGFloat pageOffsetDelta     = contentOffset.x - (visiblePagesRange.location * scrollViewWidth);
    visiblePagesRange.length    = fabs(pageOffsetDelta) > (self.pageSpacing * 0.5f) ? 2 : 1;
    
    //cap the values to ensure we don't go past the absolute bounds
    visiblePagesRange.location  = MAX(visiblePagesRange.location, 0);
    visiblePagesRange.location  = MIN(visiblePagesRange.location, numberOfPageSlots-1);
    
    visiblePagesRange.length    = contentOffset.x < 0.0f + FLT_EPSILON ? 1 : visiblePagesRange.length;
    visiblePagesRange.length    = (visiblePagesRange.location == numberOfPageSlots-1) ? 1 : visiblePagesRange.length;
    
    //Capture the current index we're on
    NSInteger oldPageIndex = self.pageIndex;
    
    //Work out at which index we are scrolled to (Whichever one is overlapping the middle
    self.scrollIndex = floor((self.scrollView.contentOffset.x + (scrollViewWidth * 0.5f)) / scrollViewWidth);
    self.scrollIndex = MIN(self.scrollIndex, numberOfPageSlots-1);
    self.scrollIndex = MAX(self.scrollIndex, 0);
    
    //if we're in reversed mode, swap the origin
    if (self.pageScrollDirection == GPageDirectionTurnLeft) {
        visiblePagesRange.location = (numberOfPageSlots - 1) - visiblePagesRange.location - (visiblePagesRange.length > 1 ? visiblePagesRange.length - 1 : 0);
        self.scrollIndex = (numberOfPageSlots - 1) - self.scrollIndex;
    }
    
    // Check if the page index has changed now, and if it has, inform the delegate
    NSInteger newPageIndex = self.pageIndex;
    if (oldPageIndex != newPageIndex && _pageScrollViewFlags.delegateDidTurnToIndex) {
        [self.delegate pagerView:self didTurnToPageAtIndex:newPageIndex];
    }
    

    __block NSInteger visiblePagesCount = 0;
    NSSet *keysToRemove = [self.visiblePagers keysOfEntriesWithOptions:0 passingTest:^BOOL (NSNumber *pageNumber, id page, BOOL *stop) {
        if ([pageNumber isKindOfClass:[NSNumber class]] == NO) { return NO; }
        if (NSLocationInRange(pageNumber.unsignedIntegerValue, visiblePagesRange) == NO)
        {
            //move the page back into the recycle pool
            id page = self.visiblePagers[pageNumber];
            //give it a chance to clear itself before we remove it
            if ([page respondsToSelector:@selector(prepareForReuse)]) {
                [page performSelector:@selector(prepareForReuse)];
            }
            NSMutableSet *recycledPagesSet = [self recycledPagesSetForPage:page];
            [recycledPagesSet addObject:page];
            [self __removeFromSuperview:page];
            return YES;
        }
        
        visiblePagesCount++;
        return NO;
    }];
    [self.visiblePagers removeObjectsForKeys:[keysToRemove allObjects]];

    if (visiblePagesCount == visiblePagesRange.length)
        return;
    
    for (NSInteger i = visiblePagesRange.location; i < NSMaxRange(visiblePagesRange); i++) {
        [self layoutViewAtScrollIndex:i];
    }
}

- (void)layoutViewAtScrollIndex:(NSInteger)scrollIndex
{
    NSInteger numberOfPageSlots = self.numberOfPageSlots;
    scrollIndex = MAX(0, scrollIndex);
    scrollIndex = MIN(numberOfPageSlots, scrollIndex);
 
    //add as a page
    if ([self.visiblePagers objectForKey:@(scrollIndex)]) {
        return;
    }
    
    id page = nil;
    NSInteger publicIndex = scrollIndex;
    if (_pageScrollViewFlags.dataSourcePageForIndex) {
        page = [self.dataSource pagerView:self pagerForIndex:publicIndex];
    }
    if (page == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Page from data source cannot be nil!" userInfo:nil];
    }
    CGRect rect = [self frameForViewAtIndex:scrollIndex];
    [self __setPager:page Frame:rect];
    [self __addSubview:page target:self.scrollView];
    [self.visiblePagers setObject:page forKey:@(scrollIndex)];
}

- (void)resetScrollViewVerticalContentInset
{
    UIEdgeInsets insets = self.scrollView.contentInset;
    if (insets.top == 0.0f && insets.bottom == 0.0f) { return; }
    
    insets.top = 0.0f;
    insets.bottom = 0.0f;
    self.scrollView.contentInset = insets;
}

- (NSMutableSet *)recycledPagesSetForPage:(id)pager
{
    NSString *identifier = kGPagerDefaultPageIdentifier;
    if ([[pager class] respondsToSelector:@selector(pageIdentifier)]) {
        NSString * identifierT = [[pager class] pageIdentifier];
        if (identifierT && identifierT.length > 0) {
            identifier = identifierT;
        }
    }
    if ([pager respondsToSelector:@selector(pageIdentifier)]) {
        NSString * identifierT = [pager pageIdentifier];;
        if (identifierT && identifierT.length > 0) {
            identifier = identifierT;
        }
    }

    NSMutableSet *set = self.recycledPageSets[identifier];
    if (set == nil) {
        set = [NSMutableSet set];
        self.recycledPageSets[identifier] = set;
    }
    return set;
}

#pragma mark - Accessor Method

- (NSInteger)pageIndex
{
    NSInteger pageIndex = self.scrollIndex;
    //cap to the maximum number of pages (which will remove the footer)
    if (pageIndex >= self.numberOfPages) {
        pageIndex = self.numberOfPages - 1;
    }
    
    return pageIndex;
}

- (void)setPageIndex:(NSInteger)pageIndex
{
    [self turnToPageAtIndex:pageIndex animated:NO];
}

- (void)setDelegate:(id<GScrollPagerDelegate>)delegate
{
    _delegate = delegate;
    _pageScrollViewFlags.delegateWillJumpToIndex    = [_delegate respondsToSelector:@selector(pagerView:willJumpToPageAtIndex:)];
    _pageScrollViewFlags.delegateDidTurnToIndex     = [_delegate respondsToSelector:@selector(pagerView:didTurnToPageAtIndex:)];
}

- (void)setDataSource:(id<GScrollPagerDataSource>)dataSource
{
    _dataSource = dataSource;
    _pageScrollViewFlags.dataSourceNumberOfPages    = [_dataSource respondsToSelector:@selector(numberOfPagesInPagerView:)];
    _pageScrollViewFlags.dataSourcePageForIndex     = [_dataSource respondsToSelector:@selector(pagerView:pagerForIndex:)];
}

- (NSArray *)visiblePages
{
    return self.visiblePagers.allValues;
}

- (NSInteger)numberOfPageSlots
{
    return self.numberOfPages;
}

#pragma mark - Override Method

- (void)__addSubview:(id)pager target:(UIView *)target
{}

- (void)__setPager:(id)pager Frame:(CGRect)rect
{}

- (void)__removeFromSuperview:(id)pager
{}

- (__kindof id)__constructPager:(Class)clazz identifier:(NSString *)identifier
{
    id pager = [[clazz alloc] init];
    return pager;
}

#pragma mark - Helper Method

- (CGRect)frameForScrollView
{
    CGRect scrollFrame      = CGRectZero;
    scrollFrame.size.width  = CGRectGetWidth(self.bounds) + self.pageSpacing;
    scrollFrame.size.height = CGRectGetHeight(self.bounds);
    scrollFrame.origin.x    = 0.0f - (self.pageSpacing * 0.5f);
    scrollFrame.origin.y    = 0.0f;
    return scrollFrame;
}

- (CGSize)contentSizeForScrollView
{
    CGSize contentSize = CGSizeZero;
    contentSize.height = CGRectGetHeight(self.bounds);
    contentSize.width  = self.numberOfPageSlots * (CGRectGetWidth(self.bounds) + self.pageSpacing);
    return contentSize;
}

- (CGPoint)contentOffsetForScrollViewAtIndex:(NSInteger)index
{
    CGPoint contentOffset = CGPointZero;
    contentOffset.y = 0.0f;
    
    if (self.pageScrollDirection == GPageDirectionTurnLeft) {
        contentOffset.x = ((self.scrollView.contentSize.width) - (CGRectGetWidth(self.scrollView.bounds) * (index+1)));
    } else {
        contentOffset.x = (CGRectGetWidth(self.scrollView.bounds) * index);
    }
    return contentOffset;
}

- (CGRect)frameForViewAtIndex:(NSInteger)index
{
    CGFloat scrollViewWidth = CGRectGetWidth(self.scrollView.bounds);
    
    CGRect pageFrame = CGRectZero;
    pageFrame.size.height   = CGRectGetHeight(self.scrollView.bounds);
    pageFrame.size.width    = scrollViewWidth - self.pageSpacing;
    pageFrame.origin        = [self contentOffsetForScrollViewAtIndex:index];
    pageFrame.origin.x      += (self.pageSpacing * 0.5f);
    return pageFrame;
}
@end

@implementation NSObject (PageIdentifier)
static char kAssociatedObjectKey_pageIdentifier;
- (void)setPageIdentifier:(NSString *)pageIdentifier {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_pageIdentifier, pageIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)pageIdentifier {
    return (NSString *)objc_getAssociatedObject(self, &kAssociatedObjectKey_pageIdentifier);
}
@end

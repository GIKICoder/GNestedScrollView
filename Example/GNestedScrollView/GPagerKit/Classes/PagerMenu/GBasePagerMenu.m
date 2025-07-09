//
//  GBasePagerMenu.m
//  GPagerKitExample
//
//  Created by GIKI on 2019/10/11.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GBasePagerMenu.h"
#import "GPagerMenuInternal.h"
@interface GPagerMenuScrollView : UIScrollView
@end


@interface GBasePagerMenu () <UIScrollViewDelegate>
@property (nonatomic, strong) GPagerMenuScrollView * scrollView;
@property (nonatomic, strong) NSArray * menuItems;
@end

@implementation GBasePagerMenu

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self __setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self __setup];
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    [self __reloadLayoutMenuItems];
}

- (void)__setup
{
    [self __setupDefault];
    [self __setupUI];
    [self __setupGesture];
}

- (void)__setupDefault
{
    _selectIndex = -1;
}

- (void)__setupUI
{
    self.scrollView = [[GPagerMenuScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:self.scrollView];
    self.scrollView.frame = self.bounds;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
}

- (void)__setupGesture
{
    UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__tapGesture:)];
    [self.scrollView addGestureRecognizer:gesture];
}

- (void)__tapGesture:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self.scrollView];
    __weak typeof(self) weakSelf = self;
    [self.menuLayouts enumerateObjectsUsingBlock:^(GPagerMenuLayoutInternal * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL temp = CGRectContainsPoint(obj.itemView.frame,point);
        if (temp) {
            [weakSelf setSelectIndex:idx];
            [weakSelf tapSelectIndex:idx];
            *stop = YES;
        }
    }];
}

- (void)tapSelectIndex:(NSInteger)index
{
    if (_pagerMenuFlags.dg_TapSelectAtIndex)
        [self.delegate pagerMenu:self didSelectItemAtIndex:index];
}

- (void)__clean
{
    [self.menuLayouts enumerateObjectsUsingBlock:^(GPagerMenuLayoutInternal *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && [obj.itemView isKindOfClass:UIView.class]) {
            [obj.itemView removeFromSuperview];
        }
    }];
    self.menuLayouts = nil;
}

- (void)__setupMenuItemLayouts
{
    if (_pagerMenuFlags.ds_MenuItems) {
        self.menuItems = [self.dataSource pagerMenuItems:self];
    } else {
        return;
    }
    __weak typeof(self) weakSelf = self;
    __block NSMutableArray * layoutsM = [NSMutableArray array];
    [self.menuItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        GPagerMenuLayoutInternal * layout = [GPagerMenuLayoutInternal new];
        
        if (self->_pagerMenuFlags.ds_MenuItemAtIndex) {
            UIView * menuItemView  = [weakSelf.dataSource pagerMenu:weakSelf itemAtIndex:idx];
            if (menuItemView) {
                [weakSelf.scrollView addSubview:menuItemView];
                layout.itemView = menuItemView;
            }
            layout.itemSize = self.itemSize;
            if (self->_pagerMenuFlags.ds_MenuItemSizeAtIndex) {
                CGSize size = [weakSelf.dataSource pagerMenu:weakSelf itemSizeAtIndex:idx];
                layout.itemSize = size;
            }
            layout.itemSpace = self.itemSpacing;
            if (self->_pagerMenuFlags.ds_MenuItemSpacingAtIndex) {
                CGFloat sapcing = [weakSelf.dataSource pagerMenu:weakSelf itemSpacingAtIndex:idx];
                layout.itemSpace = sapcing;
            }
            [layoutsM addObject:layout];
        }
    }];
    self.menuLayouts = layoutsM.copy;
}

- (void)__reloadLayoutMenuItems
{
    __block UIView * preView = nil;
    [self.menuLayouts enumerateObjectsUsingBlock:^(GPagerMenuLayoutInternal * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        {
            CGFloat width = obj.itemSize.width;
            CGFloat height = MIN(obj.itemSize.height, self.bounds.size.height);
            CGFloat left = CGRectGetMaxX(preView.frame) + obj.itemSpace;
            CGFloat top = 0.5*(self.frame.size.height-height);
            obj.itemView.frame = CGRectMake(left, top, width, height);
            obj.itemView.userInteractionEnabled = NO;
            preView = obj.itemView;
        }
    }];
    [self __layoutScrollerContentSize];
}

- (void)__layoutScrollerContentSize
{
    GPagerMenuLayoutInternal * lastMenu = [self.menuLayouts lastObject];
    CGFloat width = CGRectGetMaxX(lastMenu.itemView.frame);
    width = MAX(width, self.scrollView.frame.size.width);
    CGSize size = CGSizeMake(width,self.scrollView.frame.size.height);
    self.scrollView.contentSize = size;
    if (width <= self.scrollView.frame.size.width) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
}

- (void)__invokeDeselectItem:(GPagerMenuLayoutInternal *)obj index:(NSInteger)idx
{
    [self __deselectItemAtIndex:idx];
    
    if (_pagerMenuFlags.dg_DidUnhighlight) {
        [self.delegate pagerMenu:self didUnhighlightAtIndex:idx];
    }
}

- (void)__invokeDidselectItem:(GPagerMenuLayoutInternal *)layout index:(NSInteger)index
{
    [self __didselectItemAtIndex:index];
    
    if (_pagerMenuFlags.dg_DidHighlight) {
        [self.delegate pagerMenu:self didHighlightAtIndex:index];
    }
}

#pragma mark - Override Method

- (void)__didselectItemAtIndex:(NSUInteger)index
{}

- (void)__deselectItemAtIndex:(NSUInteger)index
{}

- (CGSize)__itemSizeAtIndex:(NSUInteger)index
{
    return CGSizeZero;
}

- (CGFloat)__itemSpacingAtIndex:(NSUInteger)index
{
    return 0;
}

#pragma mark - Public Method

- (void)setDelegate:(id<GPagerMenuDelegate>)delegate
{
    _delegate = delegate;
    
    _pagerMenuFlags.dg_TapSelectAtIndex = [delegate respondsToSelector:@selector(pagerMenu:didSelectItemAtIndex:)];
    _pagerMenuFlags.dg_DidHighlight  = [delegate respondsToSelector:@selector(pagerMenu:didHighlightAtIndex:)];
    _pagerMenuFlags.dg_DidUnhighlight  = [delegate respondsToSelector:@selector(pagerMenu:didUnhighlightAtIndex:)];
}

- (void)setDataSource:(id<GPagerMenuDataSource>)dataSource
{
    _dataSource = dataSource;
    
    _pagerMenuFlags.ds_MenuItems = [dataSource respondsToSelector:@selector(pagerMenuItems:)];
    _pagerMenuFlags.ds_MenuItemAtIndex = [dataSource respondsToSelector:@selector(pagerMenu:itemAtIndex:)];
    _pagerMenuFlags.ds_MenuItemSizeAtIndex = [dataSource respondsToSelector:@selector(pagerMenu:itemSizeAtIndex:)];
    _pagerMenuFlags.ds_MenuItemSpacingAtIndex = [dataSource respondsToSelector:@selector(pagerMenu:itemSpacingAtIndex:)];
}

- (UIView *)menuItemAtIndex:(NSInteger)index
{
    if (index >= self.menuLayouts.count) {
        return nil;
    }
    GPagerMenuLayoutInternal * layout = [self.menuLayouts objectAtIndex:index];
    return layout.itemView;
}

- (GPagerMenuLayoutInternal *)menuLayoutAtIndex:(NSInteger)index
{
    if (index >= self.menuLayouts.count) {
        return nil;
    }
    GPagerMenuLayoutInternal * layout = [self.menuLayouts objectAtIndex:index];
    return layout;
}

- (void)reloadData
{
    [self __clean];
    [self __setupMenuItemLayouts];
    [self __reloadLayoutMenuItems];
}

- (void)reloadWithIndexs:(NSArray<NSNumber *> *)indexs
{
    if (!indexs || indexs.count <= 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    NSMutableArray * arrayM = self.menuLayouts.mutableCopy;
    [indexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj integerValue];
        if (index >= self.menuLayouts.count) {
            return;
        }
        GPagerMenuLayoutInternal * remove = [arrayM objectAtIndex:index];
        [remove.itemView removeFromSuperview];
        [arrayM removeObject:remove];
        
        GPagerMenuLayoutInternal * layout = [GPagerMenuLayoutInternal new];
        if (self->_pagerMenuFlags.ds_MenuItemAtIndex) {
            UIView * menuItemView  = [weakSelf.dataSource pagerMenu:weakSelf itemAtIndex:index];
            if (menuItemView) {
                [weakSelf.scrollView addSubview:menuItemView];
                layout.itemView = menuItemView;
            }
            if (self->_pagerMenuFlags.ds_MenuItemSizeAtIndex) {
                CGSize size = [weakSelf.dataSource pagerMenu:weakSelf itemSizeAtIndex:index];
                layout.itemSize = size;
            }
            if (self->_pagerMenuFlags.ds_MenuItemSpacingAtIndex) {
                CGFloat sapcing = [weakSelf.dataSource pagerMenu:weakSelf itemSpacingAtIndex:index];
                layout.itemSpace = sapcing;
            }
        }
        [arrayM insertObject:layout atIndex:index];
    }];
    self.menuLayouts = arrayM.copy;
    [self __reloadLayoutMenuItems];
}

- (void)reloadMenuLayout
{
    [self __reloadLayoutMenuItems];
}

- (void)setSelectIndex:(NSInteger)selectIndex
{
    [self setSelectIndex:selectIndex animated:YES];
}

- (void)setSelectIndex:(NSInteger)selectIndex animated:(BOOL)animated
{
    if (_selectIndex == selectIndex) {
        return;
    }
    GPagerMenuLayoutInternal * layout = [self menuLayoutAtIndex:_selectIndex];
    GPagerMenuLayoutInternal * selectLayout = [self menuLayoutAtIndex:selectIndex];
    [self __invokeDeselectItem:layout index:_selectIndex];
    [self __invokeDidselectItem:selectLayout index:selectIndex];
    _selectIndex = selectIndex;
    [self scrollToRowAtIndex:selectIndex atScrollPosition:GPagerMenuScrollPositionMiddle animated:animated];
}

- (void)scrollToRowAtIndex:(NSUInteger)index
          atScrollPosition:(GPagerMenuScrollPosition)scrollPosition
                  animated:(BOOL)animated
{
    if (!self.scrollView.scrollEnabled) {
        return;
    }
    if (index >= self.menuLayouts.count) {
        return;
    }
    switch (scrollPosition) {
        case GPagerMenuScrollPositionNone:
        {
            [self __scrollToMenuDefaultAtIndex:index animated:animated];
        }
            break;
        case GPagerMenuScrollPositionMiddle:
        case GPagerMenuScrollPositionRight:
        case GPagerMenuScrollPositionLeft:
        {
            [self __scrollToMenuPosition:scrollPosition atIndex:index animated:animated];
        }
            break;
        default:
            break;
    }
}

- (void)__scrollToMenuPosition:(GPagerMenuScrollPosition)position atIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index >= self.menuLayouts.count) {
        return;
    }
    GPagerMenuLayoutInternal * layout = [self.menuLayouts objectAtIndex:index];
    CGRect rect = layout.itemView.frame;
    CGPoint offset = self.scrollView.contentOffset;
    CGFloat distance = 0;
    switch (position) {
        case GPagerMenuScrollPositionMiddle:
        {
            CGFloat mid_r = CGRectGetMidX(rect);
            CGFloat mid_s = CGRectGetMidX(self.scrollView.frame);
            distance = (mid_r-offset.x) - mid_s;
        }
            break;
        case GPagerMenuScrollPositionLeft:
        {
            distance = (CGRectGetMinX(rect)-offset.x) - CGRectGetMinX(self.scrollView.frame);
        }
            break;
        case GPagerMenuScrollPositionRight:
        {
            distance = (CGRectGetMaxX(rect)-offset.x) - CGRectGetMaxX(self.scrollView.frame);
        }
            break;
        default:
            break;
    }
    CGFloat newOffset = (offset.x+distance);
    CGFloat maxOffset = self.scrollView.contentSize.width - self.scrollView.frame.size.width;
    if (newOffset >= 0 && newOffset <= maxOffset) {
        offset.x += distance;
    } else {
        if (distance < 0) {
            offset.x = 0;
        } else {
            offset.x = maxOffset;
        }
    }
    
    [self.scrollView setContentOffset:offset animated:animated];
}

- (void)__scrollToMenuDefaultAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index >= self.menuLayouts.count) {
        return;
    }
    GPagerMenuLayoutInternal * layout = [self.menuLayouts objectAtIndex:index];
    CGRect rect = layout.itemView.frame;
    [self.scrollView scrollRectToVisible:rect animated:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //    CGPoint offset = self.scrollView.contentOffset;
    //    NSLog(@"offset--%f",offset);
}
@end





@implementation GPagerMenuScrollView
/**
 Fiexd: 当手指长按按钮时无法滑动scrollView的问题
 */
- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}
@end

@implementation GPagerMenuLayoutInternal

@end

//
//  DouyinMyProfileViewController.m
//  GStackScrollView_Example
//
//  Created by GIKI on 2024/8/5.
//  Copyright © 2024 GIKI. All rights reserved.
//

#import "DouyinMyProfileViewController.h"
#import "GNestedScrollView.h"
#import "DouyinProfileHeaderView.h"
#import "DouyinFeedListController.h"
#import "GControllerScrollPager.h"
#import "GPagerMenu.h"
@interface DouyinMyProfileViewController ()<GNestedScrollViewDelegate,GPagerMenuDelegate,GPagerMenuDataSource,GScrollPagerDelegate,GScrollPagerDataSource>
@property (nonatomic, strong) GNestedScrollView * stackScrollView;

/// containers
@property (nonatomic, strong) DouyinProfileHeaderView * headerView;
@property (nonatomic, strong) GPagerMenu * pagerMenu;
@property (nonatomic, strong) GControllerScrollPager * scrollPager;
@property (nonatomic, strong) NSArray * items;


@end

@implementation DouyinMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupStackScrollView];
    
    [self loadDatas];
}


- (void)setupStackScrollView
{
    GNestedScrollView * sc = [[GNestedScrollView alloc] init];
    self.stackScrollView = sc;
    sc.nestedDelegate = self;
    [self.view addSubview:sc];
    sc.frame = self.view.bounds;
    sc.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    /// add stretch header
    sc.need_stretch_header = YES;
    sc.stretchCustomFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 220);
    sc.stretchView.clipsToBounds = YES;
    sc.stretchView.image = [UIImage imageNamed:@"profile_bg.jpg"];
    
    /// add containers
    [self setupSubContainers];
}

- (void)setupSubContainers
{
    self.headerView = [DouyinProfileHeaderView new];
    self.headerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 300);
    [self.stackScrollView addContainer:self.headerView];
 
    [self setupMenu];
    
    [self setupScrollPager];
}


- (void)setupMenu
{
    self.pagerMenu = [[GPagerMenu alloc] initWithFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, 45)];
    self.pagerMenu.delegate = self;
    self.pagerMenu.dataSource = self;
    self.pagerMenu.selectItemScale = 1.2;
    [self.stackScrollView addContainer:self.pagerMenu];
}

- (void)setupScrollPager
{
    self.scrollPager = [[GControllerScrollPager alloc] init];
    self.scrollPager.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.view.frame.size.height);
    self.scrollPager.dataSource = self;
    self.scrollPager.delegate = self;
    [self.stackScrollView addContainer:self.scrollPager];
    [self.scrollPager registerPagerClass:DouyinFeedListController.class];
}


#pragma mark - loadDatas
- (void)loadDatas
{
    self.items = @[@"作品",@"私密",@"推荐",@"收藏", @"喜欢"];
    [self.pagerMenu reloadData];
    [self.pagerMenu setSelectIndex:0];
    [self.scrollPager reloadPageScrollView];
}

- (void)pageChangedWithIndex:(NSInteger)index
{
    DouyinFeedListController * feed = [self.scrollPager visiblePager];
    [self.stackScrollView addObserverStackChildScrollView:feed.collectionView];
    [self.stackScrollView updateStackOverlayContentSize];
    
}


#pragma mark - GStackScrollViewDelegate

/// 当stackScrollView offset 更新
/// @param offset offset description
- (void)g_nestedUpdateScrollOffset:(CGPoint)offset
{}

/// 当 stackScrollView 停止滚动
/// @param scrollView 当前滚动的 scrollView
- (void)g_nestedDidEndDecelerating:(UIScrollView *)scrollView
{}

/// 当 stackScrollView 开始拖拽滚动
/// @param scrollView <#scrollView description#>
- (void)g_nestedWillBeginDragging:(UIScrollView *)scrollView
{}

/// 当 stackScrollView 停止拖动
/// @param scrollView 当前拖动的 scrollView
- (void)g_nestedDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{}

/// 当stackScrollView contentSize 更新
/// @param contentSize <#contentSize description#>
- (void)g_nestedUpdateScrollContentSize:(CGSize)contentSize
{}

/// 返回当前stackView 悬停的坐标点.
/// 不实现默认hover point是处最后一个scrollView之前的所有高度.
- (CGFloat)g_nestedHoverHeight
{
    return self.stackScrollView.stretchView.frame.size.height-16;
}

/// 需要添加到StackView上的containerView
- (UIView *)g_nestedAttatchViewWithContainer:(id)container
{
    return  nil;
}

/// 可以通过delegate 回调 返回当前container 需要处理事件监听的ScrollView
/// @param container container description
/// 优先级(小于<)GStackContainerInterface
- (UIScrollView *)g_nestedScrollViewWithContainer:(id)container
{
    if (container == self.scrollPager) {
        DouyinFeedListController * feed = [self.scrollPager visiblePager];
        return  feed.collectionView;
    }
    return  nil;
}

/// 当前返回的'g_nestedScrollView' 是否需要根据contentSize的变化自动更新当前container的Frame
/// 需要实现了'g_nestedScrollView'
/// 优先级(小于<)GStackContainerInterface
- (BOOL)g_needUpdateFrameWhenContentSizeChanged:(id)container
{
    return false;
}


/// 当前返回的'g_nestedScrollView' 是否需要stackScrollView 接管手势.
/// 需要实现了'g_nestedScrollView'
/// 一般用于子Container ScrollView需要联动的ScrollView
/// 优先级(小于<)GStackContainerInterface
- (BOOL)g_needTakeoverScrollPanGesture:(id)container
{
    if (container == self.scrollPager) {
        return YES;
    }
    return NO;
}

#pragma mark - GPagerMenuDataSource

- (NSArray *)pagerMenuItems:(GBasePagerMenu *)menu
{
    return self.items;
}

- (UIView *)pagerMenu:(GBasePagerMenu *)menu itemAtIndex:(NSUInteger)index
{
    UILabel * label = [UILabel new];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [self.items objectAtIndex:index];
    return label;
}

#pragma mark - GPagerMenuDelegate

- (CGSize)pagerMenu:(GBasePagerMenu *)menu itemSizeAtIndex:(NSUInteger)index
{
    NSInteger count = self.items.count;
    CGFloat width = [UIScreen mainScreen].bounds.size.width*1.0/count;
    // NSString * item = [self.items objectAtIndex:index];
    // CGSize size = [self calculate:item sizeWithFont:[UIFont systemFontOfSize:15]];
    return CGSizeMake(width, 45);
}

- (CGFloat)pagerMenu:(GBasePagerMenu *)menu itemSpacingAtIndex:(NSUInteger)index
{
    return 0;
}

- (void)pagerMenu:(GBasePagerMenu *)menu didHighlightAtIndex:(NSUInteger)index
{
    UILabel * label = [menu menuItemAtIndex:index];
    label.textColor = [UIColor redColor];
}

- (void)pagerMenu:(GBasePagerMenu *)menu didUnhighlightAtIndex:(NSUInteger)index
{
    UILabel * label = [menu menuItemAtIndex:index];
    label.textColor = [UIColor blackColor];
}

- (void)pagerMenu:(GBasePagerMenu *)menu didSelectItemAtIndex:(NSUInteger)index
{
    [self.scrollPager turnToPageAtIndex:index animated:YES];
    [self pageChangedWithIndex:index];
}

#pragma mark - GScrollPagerDataSource

/**
 返回PageView数量
 */
- (NSInteger)numberOfPagesInPagerView:(__kindof GBaseScrollPager *)pageScrollView
{
    return self.items.count;
}

/**
 返回index下的pageView or pageController
 
 @param pagerView pagerView description
 @param pageIndex pageIndex description
 @return return value description
 */
- (UIViewController *)pagerView:(__kindof GBaseScrollPager *)pagerView pagerForIndex:(NSInteger)pageIndex
{
    DouyinFeedListController * listController = [pagerView dequeueReusablePager];
    listController.view.frame = self.scrollPager.bounds;
    return listController;
}

#pragma mark - GScrollPagerDelegate

- (void)pagerView:(__kindof GBaseScrollPager *)pagerView willJumpToPageAtIndex:(NSInteger)pageIndex
{
    
}

- (void)pagerView:(__kindof GBaseScrollPager *)pagerView didTurnToPageAtIndex:(NSInteger)pageIndex
{
    [self.pagerMenu setSelectIndex:pageIndex];
    [self pageChangedWithIndex:pageIndex];
}

#pragma mark - helper

- (CGSize)calculate:(NSString *)string sizeWithFont:(UIFont *)font
{
    CGSize size;
    NSDictionary *attribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    size = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    return size;
}

@end


//
//  DouyinProfileViewController.m
//  GStackScrollView_Example
//
//  Created by GIKI on 2024/8/5.
//  Copyright © 2024 GIKI. All rights reserved.
//

#import "DouyinProfileViewController.h"
#import "GNestedScrollView.h"
#import "DouyinProfileHeaderView.h"
#import "DouyinFeedListController.h"
@interface DouyinProfileViewController ()<GNestedScrollViewDelegate>
@property (nonatomic, strong) GNestedScrollView * stackScrollView;

/// containers
@property (nonatomic, strong) DouyinProfileHeaderView * headerView;

@property (nonatomic, strong) DouyinFeedListController * feedListVc;
@end

@implementation DouyinProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupStackScrollView];
    

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
    
    [self addFeedList];
}


- (void)addFeedList
{
    self.feedListVc = [DouyinFeedListController new];
    [self addChildViewController:self.feedListVc];
    self.feedListVc.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    [self.stackScrollView addContainer:self.feedListVc];
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
    return self.stackScrollView.stretchView.frame.size.height;
}

/// 需要添加到StackView上的containerView
- (UIView *)g_nestedAttatchViewWithContainer:(id)container
{
    if (container == self.feedListVc) {
        return self.feedListVc.view;
    }
    return  nil;
}

/// 可以通过delegate 回调 返回当前container 需要处理事件监听的ScrollView
/// @param container container description
/// 优先级(小于<)GStackContainerInterface
- (UIScrollView *)g_nestedScrollViewWithContainer:(id)container
{
    if (container == self.feedListVc) {
        return self.feedListVc.collectionView;
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
    if (container == self.feedListVc) {
        return YES;
    }
    return NO;
}

@end

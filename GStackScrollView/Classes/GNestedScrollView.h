//
//  GStackScrollView.h
//  GStackScrollView
//
//  Created by GIKI on 2024/8/5.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GNestedContainerInterface <NSObject>

@optional
/// 需要添加到StackView上的containerView
- (UIView *)g_nestedAttatchView;

/// 需要处理事件监听的ScrollView
- (UIScrollView *)g_nestedScrollView;

/// 当前返回的'g_nestedScrollView' 是否需要根据contentSize的变化自动更新当前container的Frame
/// 需要实现了'g_nestedScrollView'
- (BOOL)g_needUpdateFrameWhenContentSizeChanged;

/// 返回当前 g_nestedAttatchView 的height
/// 如果为0,则使用'g_needUpdateFrameWhenContentSizeChanged'
/// 根据contentsize获取自己高度.
- (CGFloat)g_customAttatchViewHeight;

/// 当前返回的'g_nestedScrollView' 是否需要stackScrollView 接管手势.
/// 需要实现了'g_nestedScrollView'
/// 一般用于子Container ScrollView需要联动的ScrollView
- (BOOL)g_needTakeoverScrollPanGesture;

@end

@protocol GNestedScrollViewDelegate <NSObject>

@optional

/// 当stackScrollView offset 更新
/// @param offset offset description
- (void)g_nestedUpdateScrollOffset:(CGPoint)offset;

/// 当 stackScrollView 停止滚动
/// @param scrollView 当前滚动的 scrollView
- (void)g_nestedDidEndDecelerating:(UIScrollView *)scrollView;

/// 当 stackScrollView 开始拖拽滚动
/// @param scrollView <#scrollView description#>
- (void)g_nestedWillBeginDragging:(UIScrollView *)scrollView;

/// 当 stackScrollView 停止拖动
/// @param scrollView 当前拖动的 scrollView
- (void)g_nestedDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

/// 当stackScrollView contentSize 更新
/// @param contentSize <#contentSize description#>
- (void)g_nestedUpdateScrollContentSize:(CGSize)contentSize;

/// 返回当前stackView 悬停的坐标点.
/// 不实现默认hover point是处最后一个scrollView之前的所有高度.
- (CGFloat)g_nestedHoverHeight;

/// 需要添加到StackView上的containerView
/// 如果Container是UIView的子类. 不指定AttatchView会默认将Container 添加到StackScrollView
- (UIView *)g_nestedAttatchViewWithContainer:(id)container;

/// 可以通过delegate 回调 返回当前container 需要处理事件监听的ScrollView
/// @param container container description
/// 优先级(小于<)GStackContainerInterface
- (UIScrollView *)g_nestedScrollViewWithContainer:(id)container;

/// 当前返回的'g_nestedScrollView' 是否需要根据contentSize的变化自动更新当前container的Frame
/// 需要实现了'g_nestedScrollView'
/// 优先级(小于<)GStackContainerInterface
- (BOOL)g_needUpdateFrameWhenContentSizeChanged:(id)container;

/// 返回当前 g_nestedAttatchView 的height
/// 如果为0,则使用'g_needUpdateFrameWhenContentSizeChanged'
/// 根据contentsize获取自己高度.
/// 优先级(大于>g_needUpdateFrameWhenContentSizeChanged)
- (CGFloat)g_customAttatchViewHeight:(id)container;

/// 当前返回的'g_nestedScrollView' 是否需要stackScrollView 接管手势.
/// 需要实现了'g_nestedScrollView'
/// 一般用于子Container ScrollView需要联动的ScrollView
/// 优先级(小于<)GStackContainerInterface
- (BOOL)g_needTakeoverScrollPanGesture:(id)container;

@end

/// <#Description#>
@interface GNestedScrollView : UIScrollView

/// 初始化stack containers
/// @param containers protocol<GStackContainerInterface>任意类型 or UIView 类型
- (instancetype)initWithStackContainers:(NSArray<id> *)containers;

/// 往stackView中添加一个container
/// @param container 可遵守<GStackContainerInterface>or任意UIView类型
- (void)addContainer:(id)container;

/// 往stackView中index位置插入一个container
/// @param container 可遵守<GStackContainerInterface>or任意UIView类型
/// @param index <#index description#>
- (void)insertContainer:(id)container atIndex:(NSInteger)index;

/// 往stackView中添加一个container
/// @param container 可遵守<GStackContainerInterface>or任意UIView类型
/// @param before 在before container 前面
- (void)addContainer:(id)container before:(id)before;

/// 往stackView中添加一个container
/// @param container 可遵守<GStackContainerInterface>or任意UIView类型
/// @param after 在after container 后面
- (void)addContainer:(id)container after:(id)after;

/// 从stackView中移除某个container
/// @param container 可遵守<GStackContainerInterface>or任意UIView类型
- (void)removeContainer:(id)container;

/// 从stackView中移除所有的container
- (void)removeAllContainers;

/// 是否添加了container
/// - Parameter container: <#container description#>
- (BOOL)containWithContainer:(id)container;

/// 获取所有的container
- (NSArray *)allContainers;

/// 最后一个container
- (id)lastContainer;

/// 第一个container
- (id)firstContainer;

/// 滚动到对应的container
/// @param container <#container description#>
/// @param animated <#animation description#>
- (void)scrollToContainer:(id)container animated:(BOOL)animated;

/// 滚动到顶部
- (void)scrollToTopContainer:(BOOL)animated;

/// id<GStackScrollViewDelegate>
@property (nonatomic, weak  ) id<GNestedScrollViewDelegate>  nestedDelegate;

/// overlay View,用于处理滑动手势的ScrollView.
/// 刷新控件可添加到此scrollView上.
@property (nonatomic, strong, readonly) UIScrollView * overlayView;

/// 放大效果背景图,当need_stretch_header==YES,生效.
@property (nonatomic, strong, readonly) UIImageView * stretchView;

/// 背景图自定义 frame. 默认为 nil, 背景图按照首个 container 布局
@property (nonatomic, assign) CGRect stretchCustomFrame;

/// 是否添加缩放 Header default: NO
@property (nonatomic, assign) BOOL  need_stretch_header;

/// 当stackScollView bounces状态下,是否允许子scrollView, 继续下拉操作.
/// self.bounces == NO 生效.
/// Default: YES
/// 通常用于实现Header不拉伸,顶部固定,下面listView 可下拉刷新.
@property (nonatomic, assign) BOOL  childScrollPullWhenBounces;

/// 重置接管手势
/// @param container <#container description#>
- (void)resetTakeOverPanGestureWithContainer:(id)container;

/// 添加子child scrollView 监听.
/// @param scrollView scrollView description
/// @brief 一般用于多层横向嵌套的竖向child scrollView.
- (void)addObserverStackChildScrollView:(__kindof UIScrollView *)scrollView;

/// 更新stackOverlayView的contentSize
/// 非横向嵌套scrollView的情况下无需调用.
/// 在横向嵌套的scrollView pageIndex 更改时调用更新
- (void)updateStackOverlayContentSize;

- (void)setNeedsUpdateContainer;
@end

NS_ASSUME_NONNULL_END

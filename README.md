
# GNestedScrollView

GNestedScrollView 是一个基于Objective-c实现的嵌套滚动处理组件，专为实现复杂的嵌套滚动需求而设计。它提供了一种简洁且高效的方式，轻松应对多种嵌套滚动场景。

## 示例

`抖音个人页效果`

<a href="https://github.com/user-attachments/assets/8e7bfa29-1920-4af7-acff-22dac0b64875"><img src="https://github.com/user-attachments/assets/8e7bfa29-1920-4af7-acff-22dac0b64875" alt="Screenshot 1" width="300"/></a>
<a href="https://github.com/user-attachments/assets/47ca060d-9401-44a8-8f5d-2c51a05a2f94"><img src="https://github.com/user-attachments/assets/47ca060d-9401-44a8-8f5d-2c51a05a2f94" alt="Screenshot 1" width="300"/></a>
<a href="https://github.com/user-attachments/assets/1b7da95e-988a-4c62-b240-12e85c8513dd"><img src="https://github.com/user-attachments/assets/1b7da95e-988a-4c62-b240-12e85c8513dd" alt="Screenshot 1" width="300"/></a>


## 特性

1. **线性布局的 ScrollView**：自动对内部的 container 进行线性布局，简化布局管理。
2. **Stretchable Header View 支持**：支持可拉伸的头部视图，增强用户体验。
3. **Stretchable Header + Horizontal Swipable Tab View 支持**：支持可拉伸的头部视图 + 横向可滑动的 Tab 视图，提供流畅的滑动体验。
4. **快速实现各种嵌套效果**：仅需一个类，即可实现多种复杂的嵌套效果，对SubContainer列表无入侵。 

## 安装

你可以通过以下方式将 GStackScrollView 安装到你的项目中：

```
pod 'GStackScrollView'
```


## 使用

以下是一个简单的示例，展示了如何在项目中使用 GStackScrollView：

```objc
/// setup
GNestedScrollView * sc = [[GNestedScrollView alloc] init];
self.stackScrollView = sc;
sc.stackDelegate = self;
[self.view addSubview:sc];
sc.frame = self.view.bounds;
sc.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

/// add stretch header
sc.need_stretch_header = YES;
sc.stretchCustomFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 220);
sc.stretchView.clipsToBounds = YES;
sc.stretchView.image = [UIImage imageNamed:@"profile_bg.jpg"];

/// add header 
self.headerView = [DouyinProfileHeaderView new];
self.headerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 300);
[self.stackScrollView addContainer:self.headerView];

/// add feed list
self.feedListVc = [DouyinFeedListController new];
[self addChildViewController:self.feedListVc];
self.feedListVc.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
[self.stackScrollView addContainer:self.feedListVc];
```

```objc
/// 实现 GStackScrollViewDelegate

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
```

## 贡献

我们欢迎任何形式的贡献！请阅读 [贡献指南](CONTRIBUTING.md) 来了解详细信息。

1. Fork 本仓库
2. 创建你的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request


---

感谢你使用 GStackScrollView！希望它能帮助你轻松实现嵌套滚动效果。如果你喜欢这个项目，请给我们一个 star！✨


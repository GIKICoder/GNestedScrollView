import UIKit

// MARK: - Protocols

protocol NestedScrollViewContainer: AnyObject {
    var attachView: UIView { get }
    var managedScrollView: UIScrollView? { get }
    var needsAutoFrameUpdate: Bool { get }
    var customHeight: CGFloat { get }
    var needsPanGestureTakeover: Bool { get }
}

extension NestedScrollViewContainer {
    var managedScrollView: UIScrollView? { nil }
    var needsAutoFrameUpdate: Bool { false }
    var customHeight: CGFloat { 0 }
    var needsPanGestureTakeover: Bool { false }
}

protocol NestedScrollViewDelegate: AnyObject {
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateOffset offset: CGPoint)
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDecelerating: Bool)
    func nestedScrollView(_ scrollView: NestedScrollView, willBeginDragging: Bool)
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDragging willDecelerate: Bool)
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateContentSize size: CGSize)
    func hoverHeight(for scrollView: NestedScrollView) -> CGFloat
}

extension NestedScrollViewDelegate {
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateOffset offset: CGPoint) {}
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDecelerating: Bool) {}
    func nestedScrollView(_ scrollView: NestedScrollView, willBeginDragging: Bool) {}
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDragging willDecelerate: Bool) {}
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateContentSize size: CGSize) {}
    func hoverHeight(for scrollView: NestedScrollView) -> CGFloat {
        return scrollView.topContainerHeight
    }
}

// MARK: - NestedScrollView

final class NestedScrollView: UIScrollView {
    
    // MARK: - Properties
    
    weak var nestedDelegate: NestedScrollViewDelegate?
    
    private(set) lazy var overlayScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.layer.zPosition = .greatestFiniteMagnitude
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()
    
    private(set) lazy var stretchImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private var containers: [ContainerWrapper] = []
    private var childScrollViews: NSHashTable<UIScrollView> = NSHashTable.weakObjects()
    private var childScrollViewOffsets: NSMapTable<UIScrollView, NSNumber> = NSMapTable.weakToStrongObjects()
    
    private var originalStretchFrame: CGRect = .zero
    private var isHovering: Bool = false
    
    // MARK: - Configuration
    
    var enableStretchHeader: Bool = false {
        didSet {
            updateStretchHeaderVisibility()
        }
    }
    
    var stretchCustomFrame: CGRect = .zero
    var allowChildScrollWhenBouncing: Bool = true
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }
    
    convenience init(containers: [Any]) {
        self.init(frame: .zero)
        addContainers(containers)
    }
    
    private func setupScrollView() {
        showsVerticalScrollIndicator = false
        scrollsToTop = false
        
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
    }
    
    // MARK: - View Lifecycle
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        overlayScrollView.removeFromSuperview()
        
        guard let newSuperview = newSuperview else { return }
        
        newSuperview.insertSubview(overlayScrollView, belowSubview: self)
        addGestureRecognizer(overlayScrollView.panGestureRecognizer)
        addSubview(stretchImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if overlayScrollView.frame != frame {
            overlayScrollView.frame = frame
        }
    }
    
    // MARK: - Container Management
    
    func addContainer(_ container: Any) {
        let wrapper = ContainerWrapper(container: container)
        containers.append(wrapper)
        updateLayout()
    }
    
    func insertContainer(_ container: Any, at index: Int) {
        let wrapper = ContainerWrapper(container: container)
        let insertIndex = min(index, containers.count)
        containers.insert(wrapper, at: insertIndex)
        updateLayout()
    }
    
    func addContainer(_ container: Any, before beforeContainer: Any) {
        if let index = containers.firstIndex(where: { $0.isEqual(to: beforeContainer) }) {
            insertContainer(container, at: index)
        } else {
            addContainer(container)
        }
    }
    
    func addContainer(_ container: Any, after afterContainer: Any) {
        if let index = containers.firstIndex(where: { $0.isEqual(to: afterContainer) }) {
            insertContainer(container, at: index + 1)
        } else {
            insertContainer(container, at: 0)
        }
    }
    
    func removeContainer(_ container: Any) {
        if let index = containers.firstIndex(where: { $0.isEqual(to: container) }) {
            let wrapper = containers[index]
            wrapper.attachView.removeFromSuperview()
            containers.remove(at: index)
            updateLayout()
        }
    }
    
    func removeAllContainers() {
        containers.forEach { $0.attachView.removeFromSuperview() }
        containers.removeAll()
        updateLayout()
    }
    
    func contains(_ container: Any) -> Bool {
        return containers.contains { $0.isEqual(to: container) }
    }
    
    func addContainers(_ containers: [Any]) {
        containers.forEach { addContainer($0) }
    }
    
    // MARK: - Scroll Control
    
    func scrollToContainer(_ container: Any, animated: Bool) {
        guard let wrapper = containers.first(where: { $0.isEqual(to: container) }) else { return }
        let targetOffset = CGPoint(x: contentOffset.x, y: wrapper.attachView.frame.minY)
        overlayScrollView.setContentOffset(targetOffset, animated: animated)
    }
    
    func scrollToTop(animated: Bool) {
        overlayScrollView.setContentOffset(.zero, animated: animated)
    }
    
    // MARK: - Child ScrollView Management
    
    func addChildScrollView(_ scrollView: UIScrollView) {
        guard !childScrollViews.contains(scrollView) else { return }
        
        childScrollViewOffsets.setObject(NSNumber(value: 0), forKey: scrollView)
        childScrollViews.add(scrollView)
        
        scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
        
        observeScrollView(scrollView)
    }
    
    func updateOverlayContentSize() {
        let totalHeight = calculateTotalContentHeight()
        overlayScrollView.contentSize = CGSize(width: contentSize.width, height: totalHeight)
        nestedDelegate?.nestedScrollView(self, didUpdateContentSize: CGSize(width: contentSize.width, height: totalHeight))
    }
    
    // MARK: - Private Methods
    
    private func updateLayout() {
        var yOffset: CGFloat = 0
        
        for wrapper in containers {
            let attachView = wrapper.attachView
            
            if attachView.superview != self {
                addSubview(attachView)
                observeContainer(wrapper)
            }
            
            var frame = attachView.frame
            frame.origin.y = yOffset
            attachView.frame = frame
            yOffset = frame.maxY
            
            if enableStretchHeader && wrapper === containers.first {
                setupStretchHeader(for: attachView)
            }
        }
        
        contentSize = CGSize(width: UIScreen.main.bounds.width, height: yOffset)
        updateOverlayContentSize()
    }
    
    private func setupStretchHeader(for view: UIView) {
        if !subviews.contains(stretchImageView) {
            insertSubview(stretchImageView, at: 0)
        }
        
        stretchImageView.frame = stretchCustomFrame.isEmpty ? view.bounds : stretchCustomFrame
        originalStretchFrame = stretchImageView.frame
    }
    
    private func updateStretchHeaderVisibility() {
        stretchImageView.isHidden = !enableStretchHeader
    }
    
    private func updateStretchHeader(offset: CGFloat) {
        guard enableStretchHeader else { return }
        
        if offset >= 0 {
            stretchImageView.frame = CGRect(
                x: 0,
                y: 0,
                width: originalStretchFrame.width,
                height: originalStretchFrame.height
            )
        } else {
            stretchImageView.frame = CGRect(
                x: 0,
                y: offset,
                width: originalStretchFrame.width,
                height: originalStretchFrame.height - offset
            )
        }
    }
    
    private func observeContainer(_ wrapper: ContainerWrapper) {
        let attachView = wrapper.attachView
        
        // Observe frame changes
        attachView.layer.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
        
        // Observe managed scroll view if available
        if let scrollView = wrapper.managedScrollView {
            scrollView.scrollsToTop = false
            
            if wrapper.needsPanGestureTakeover {
                scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
            }
            
            observeScrollView(scrollView)
        }
    }
    
    private func observeScrollView(_ scrollView: UIScrollView) {
        scrollView.addObserver(self, forKeyPath: "contentSize", options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds" {
            updateLayout()
        } else if keyPath == "contentSize" {
            handleContentSizeChange(for: object, change: change)
        }
    }
    
    private func handleContentSizeChange(for object: Any?, change: [NSKeyValueChangeKey: Any]?) {
        guard let scrollView = object as? UIScrollView,
              let change = change,
              let newValue = change[.newKey] as? NSValue,
              let oldValue = change[.oldKey] as? NSValue else { return }
        
        let newSize = newValue.cgSizeValue
        let oldSize = oldValue.cgSizeValue
        
        guard newSize != oldSize else { return }
        
        if let wrapper = containers.first(where: { $0.managedScrollView === scrollView }) {
            if wrapper.needsAutoFrameUpdate {
                var frame = wrapper.attachView.frame
                frame.size = newSize
                wrapper.attachView.frame = frame
            } else if wrapper.customHeight > 0 {
                var frame = wrapper.attachView.frame
                frame.size.height = wrapper.customHeight
                wrapper.attachView.frame = frame
            }
        }
        
        updateOverlayContentSize()
    }
    
    private func calculateTotalContentHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        
        for wrapper in containers {
            if let scrollView = wrapper.managedScrollView {
                let contentHeight = scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom
                totalHeight += max(contentHeight, scrollView.frame.height)
            } else {
                totalHeight += wrapper.attachView.frame.height
            }
        }
        
        return totalHeight
    }
    
    var topContainerHeight: CGFloat {
        guard containers.count > 1 else { return 0 }
        
        return containers.dropLast().reduce(0) { result, wrapper in
            result + wrapper.attachView.frame.height
        }
    }
    
    deinit {
        containers.forEach { wrapper in
            wrapper.attachView.layer.removeObserver(self, forKeyPath: "bounds")
            wrapper.managedScrollView?.removeObserver(self, forKeyPath: "contentSize")
        }
        
        childScrollViews.allObjects.forEach { scrollView in
            scrollView.removeObserver(self, forKeyPath: "contentSize")
        }
    }
}

// MARK: - UIScrollViewDelegate

extension NestedScrollView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let hoverHeight = nestedDelegate?.hoverHeight(for: self) ?? topContainerHeight
        let offset = scrollView.contentOffset.y
        
        nestedDelegate?.nestedScrollView(self, didUpdateOffset: scrollView.contentOffset)
        
        // Handle non-bouncing scroll behavior
        if !bounces && offset <= 0 {
            isHovering = false
            contentOffset = .zero
            
            if !allowChildScrollWhenBouncing {
                return
            }
            
            if let lastWrapper = containers.last,
               let lastScrollView = lastWrapper.managedScrollView {
                overlayScrollView.contentOffset = .zero
                overlayScrollView.panGestureRecognizer.state = .cancelled
                return
            }
        }
        
        updateStretchHeader(offset: offset)
        
        // Handle hover behavior
        if offset < hoverHeight {
            isHovering = false
            contentOffset = scrollView.contentOffset
            
            if let lastWrapper = containers.last,
               let lastScrollView = lastWrapper.managedScrollView {
                if childScrollViewOffsets.object(forKey: lastScrollView) != nil {
                    childScrollViewOffsets.setObject(NSNumber(value: 0), forKey: lastScrollView)
                }
                lastScrollView.contentOffset = .zero
                
                childScrollViews.allObjects.forEach { childScrollView in
                    childScrollView.contentOffset = .zero
                    childScrollViewOffsets.setObject(NSNumber(value: 0), forKey: childScrollView)
                }
            }
        } else {
            isHovering = true
            contentOffset = CGPoint(x: 0, y: hoverHeight)
            
            if let lastWrapper = containers.last,
               let lastScrollView = lastWrapper.managedScrollView {
                let childOffset = CGPoint(x: 0, y: offset - contentOffset.y)
                lastScrollView.contentOffset = childOffset
                
                if childScrollViewOffsets.object(forKey: lastScrollView) != nil {
                    childScrollViewOffsets.setObject(NSNumber(value: offset), forKey: lastScrollView)
                }
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        nestedDelegate?.nestedScrollView(self, willBeginDragging: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        nestedDelegate?.nestedScrollView(self, didEndDecelerating: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        nestedDelegate?.nestedScrollView(self, didEndDragging: decelerate)
    }
}

// MARK: - ContainerWrapper

private class ContainerWrapper {
    let container: Any
    
    init(container: Any) {
        self.container = container
    }
    
    var attachView: UIView {
        if let nestedContainer = container as? NestedScrollViewContainer {
            return nestedContainer.attachView
        } else if let view = container as? UIView {
            return view
        } else {
            fatalError("Container must conform to NestedScrollViewContainer or be a UIView")
        }
    }
    
    var managedScrollView: UIScrollView? {
        return (container as? NestedScrollViewContainer)?.managedScrollView
    }
    
    var needsAutoFrameUpdate: Bool {
        return (container as? NestedScrollViewContainer)?.needsAutoFrameUpdate ?? false
    }
    
    var customHeight: CGFloat {
        return (container as? NestedScrollViewContainer)?.customHeight ?? 0
    }
    
    var needsPanGestureTakeover: Bool {
        return (container as? NestedScrollViewContainer)?.needsPanGestureTakeover ?? false
    }
    
    func isEqual(to other: Any) -> Bool {
        if let otherObject = other as AnyObject?, let selfObject = container as AnyObject? {
            return selfObject === otherObject
        }
        return false
    }
}
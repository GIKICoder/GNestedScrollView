import UIKit

/*
// MARK: - Example Header View

class ProfileHeaderView: UIView, NestedScrollViewContainer {
    
    var attachView: UIView { return self }
    var managedScrollView: UIScrollView? { return nil }
    var needsAutoFrameUpdate: Bool { return false }
    var customHeight: CGFloat { return 0 }
    var needsPanGestureTakeover: Bool { return false }
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Avatar
        avatarImageView.backgroundColor = .systemGray4
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        
        // Labels
        nameLabel.text = "John Doe"
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .label
        
        descriptionLabel.text = "iOS Developer"
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        
        // Add subviews
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        
        // Layout
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 60),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}

// MARK: - Example List Container

class FeedListContainer: UIViewController, NestedScrollViewContainer {
    
    var attachView: UIView { return view }
    var managedScrollView: UIScrollView? { return tableView }
    var needsAutoFrameUpdate: Bool { return true }
    var customHeight: CGFloat { return 0 }
    var needsPanGestureTakeover: Bool { return true }
    
    private let tableView = UITableView()
    private let data = Array(0..<50).map { "Item \($0)" }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension FeedListContainer: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Example Usage

class ExampleViewController: UIViewController {
    
    private var nestedScrollView: NestedScrollView!
    private var headerView: ProfileHeaderView!
    private var feedListContainer: FeedListContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNestedScrollView()
    }
    
    private func setupNestedScrollView() {
        // Initialize nested scroll view
        nestedScrollView = NestedScrollView()
        nestedScrollView.nestedDelegate = self
        nestedScrollView.enableStretchHeader = true
        nestedScrollView.stretchCustomFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 220)
        
        // Set background image for stretch effect
        nestedScrollView.stretchImageView.backgroundColor = .systemBlue
        
        view.addSubview(nestedScrollView)
        nestedScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nestedScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nestedScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nestedScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nestedScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Create and add containers
        setupContainers()
    }
    
    private func setupContainers() {
        // Header view
        headerView = ProfileHeaderView()
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        nestedScrollView.addContainer(headerView)
        
        // Feed list
        feedListContainer = FeedListContainer()
        addChild(feedListContainer)
        feedListContainer.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        nestedScrollView.addContainer(feedListContainer)
        feedListContainer.didMove(toParent: self)
    }
}

// MARK: - NestedScrollViewDelegate

extension ExampleViewController: NestedScrollViewDelegate {
    
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateOffset offset: CGPoint) {
        // Handle scroll offset updates
        print("Scroll offset: \(offset)")
    }
    
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDecelerating: Bool) {
        // Handle scroll end
    }
    
    func nestedScrollView(_ scrollView: NestedScrollView, willBeginDragging: Bool) {
        // Handle drag begin
    }
    
    func nestedScrollView(_ scrollView: NestedScrollView, didEndDragging willDecelerate: Bool) {
        // Handle drag end
    }
    
    func nestedScrollView(_ scrollView: NestedScrollView, didUpdateContentSize size: CGSize) {
        // Handle content size updates
        print("Content size: \(size)")
    }
    
    func hoverHeight(for scrollView: NestedScrollView) -> CGFloat {
        // Return the height at which the scroll view should start hovering
        // Default is the height of all containers except the last one
        return headerView.frame.height
    }
}

// MARK: - Alternative Simple Usage

class SimpleExampleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Create simple views
        let headerView = UIView()
        headerView.backgroundColor = .systemRed
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)
        
        let contentView = UIView()
        contentView.backgroundColor = .systemGreen
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 400)
        
        // Create nested scroll view with simple containers
        let nestedScrollView = NestedScrollView(containers: [headerView, contentView])
        nestedScrollView.enableStretchHeader = true
        nestedScrollView.stretchImageView.backgroundColor = .systemPurple
        
        view.addSubview(nestedScrollView)
        nestedScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nestedScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nestedScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nestedScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nestedScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
*/

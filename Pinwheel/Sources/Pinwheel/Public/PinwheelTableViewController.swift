import UIKit

public class PinwheelTableViewController: UITableViewController {
    private lazy var selectorTitleView: SelectorTitleView = {
        let titleView = SelectorTitleView(withAutoLayout: true)
        titleView.delegate = self
        return titleView
    }()

    private var bottomSheet: BottomSheet?

    lazy var indexer: Indexer = {
        let section = sections[safe: State.lastSelectedSection]
        let names = section?.capitalizedTitles() ?? [String]()
        let indexer = Indexer(names: names)
        return indexer
    }()

    private var sections: [PinwheelSection]

    public init(sections: [PinwheelSection]) {
        self.sections = sections
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = State.lastSelectedIndexPath {
            if let viewController = viewControllerAtIndexPath(indexPath: indexPath) {
                if let bottomSheet = viewController as? BottomSheet {
                    present(bottomSheet, animated: true)
                } else {
                    present(viewController, animated: false)
                }
            }
        }
    }

    private func setup() {
        tableView.register(UITableViewCell.self)
        tableView.delegate = self
        tableView.separatorStyle = .none
        navigationItem.titleView = selectorTitleView

        selectorTitleView.title = titleForItemAtSection(section: State.lastSelectedSection)?.uppercased()
        tableView.sectionIndexColor = .primaryAction
        tableView.backgroundColor = .primaryBackground
        setNeedsStatusBarAppearanceUpdate()
    }

    private func evaluateRealIndexPath(for indexPath: IndexPath) -> IndexPath? {
        guard State.lastSelectedSection <= sections.count else { return nil }
        return indexer.evaluateRealIndexPath(for: indexPath, originalSection: State.lastSelectedSection)
    }

    public override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if viewControllerToPresent.modalPresentationStyle == .pageSheet {
            viewControllerToPresent.modalPresentationStyle = .fullScreen
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func titleForItemAtSection(section: Int) -> String? {
        return sections[safe: section]?.title
    }

    func viewControllerAtIndexPath(indexPath: IndexPath) -> UIViewController? {
        guard let section = sections[safe: indexPath.section] else { return nil }
        guard let item = section.items[safe: indexPath.row] else { return nil }
        var viewController: UIViewController = item.viewController
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch item.tabletDisplayMode {
            case .master:
                viewController = SplitViewController(masterViewController: viewController)
            case .detail:
                viewController = SplitViewController(detailViewController: viewController)
            default:
                break
            }
        default:
            break
        }

        let containmentOptions = (viewController as? Containable)?.containmentOptions ?? .none

        if containmentOptions.contains(.navigationController) {
            viewController = NavigationController(rootViewController: viewController)
        }

        if containmentOptions.contains(.tabBarController) {
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [viewController]
            viewController = tabBarController
        }

        if containmentOptions.contains(.bottomSheet) {
            let bottomSheet = BottomSheet(rootViewController: viewController)
            viewController = bottomSheet
        }

        return viewController
    }
}

// MARK: - UITableViewDelegate

public extension PinwheelTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return indexer.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indexer.numberOfRowsInSection(section: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        cell.textLabel?.text = indexer.value(for: indexPath)
        cell.textLabel?.font = .body
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let cellTextColor: UIColor = .primaryText
        cell.textLabel?.textColor = cellTextColor

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let realIndexPath = evaluateRealIndexPath(for: indexPath) {
            State.lastSelectedIndexPath = realIndexPath
            if let viewController = viewControllerAtIndexPath(indexPath: realIndexPath) {
                present(viewController, animated: true)
            }
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return indexer.sections
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return indexer.sections[section]
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .secondaryText
            headerView.textLabel?.font = UIFont.caption
        }
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
}

// MARK: - SelectorTitleViewDelegate

extension PinwheelTableViewController: SelectorTitleViewDelegate {
    func selectorTitleViewDidSelectButton(_ selectorTitleView: SelectorTitleView) {
        guard State.lastSelectedSection <= sections.count else { return }

        let items = sections.map { BasicTableViewItem(title: $0.title.uppercased()) }
        let sectionsTableView = BasicTableView(items: items)
        sectionsTableView.selectedIndexPath = IndexPath(row: State.lastSelectedSection, section: 0)
        sectionsTableView.delegate = self
        bottomSheet = BottomSheet(view: sectionsTableView, draggableArea: .everything)
        if let controller = bottomSheet {
            present(controller, animated: true)
        }
    }
}

// MARK: - BasicTableViewDelegate

extension PinwheelTableViewController: BasicTableViewDelegate {
    public func basicTableView(_ basicTableView: BasicTableView, didSelectItemAtIndex index: Int) {
        State.lastSelectedSection = index
        selectorTitleView.title = titleForItemAtSection(section: index)?.uppercased()

        let section = sections[safe: State.lastSelectedSection]
        let names = section?.capitalizedTitles() ?? [String]()
        self.indexer = Indexer(names: names)

        tableView.reloadData()
        bottomSheet?.state = .dismissed
    }
}

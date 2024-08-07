import UIKit

public class PinwheelTableViewController: UITableViewController {
    private lazy var selectorTitleView: SelectorTitleView = {
        let titleView = SelectorTitleView(withAutoLayout: true)
        titleView.delegate = self
        return titleView
    }()

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
                present(viewController, animated: true)
            }
        }
    }

    private func setup() {
        tableView.register(UITableViewCell.self)
        tableView.delegate = self
        tableView.separatorStyle = .none
        navigationItem.titleView = selectorTitleView

        selectorTitleView.title = titleForItemAtSection(section: State.lastSelectedSection)
        tableView.sectionIndexColor = .actionText
        tableView.backgroundColor = .primaryBackground
        setNeedsStatusBarAppearanceUpdate()
    }

    private func evaluateRealIndexPath(for indexPath: IndexPath) -> IndexPath? {
        guard State.lastSelectedSection <= sections.count else { return nil }
        return indexer.evaluateRealIndexPath(for: indexPath, originalSection: State.lastSelectedSection)
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
            headerView.textLabel?.font = UIFont.footnote
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

        let items = sections.map { TextTableViewItem(title: $0.title) }
        let sectionsController = PinwheelSectionsViewController(items: items)
        if #available(iOS 15.0, *) {
            sectionsController.sheetPresentationController?.detents = [.medium()]
            sectionsController.sheetPresentationController?.preferredCornerRadius = .spacingXL
            sectionsController.sheetPresentationController?.prefersGrabberVisible = true
        }
        sectionsController.delegate = self
        present(sectionsController, animated: true)
    }
}

extension PinwheelTableViewController: PinwheelSectionsViewControllerDelegate {
    func pinWheelSectionsViewController(_ pinWheelSectionsViewController: PinwheelSectionsViewController, didSelectItemAtIndex index: Int) {
        State.lastSelectedSection = index
        selectorTitleView.title = titleForItemAtSection(section: index)

        let section = sections[safe: State.lastSelectedSection]
        let names = section?.capitalizedTitles() ?? [String]()
        self.indexer = Indexer(names: names)

        tableView.reloadData()
        dismiss(animated: true)
    }
}

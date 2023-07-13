import Pinwheel

class PinViewControllerBottomSheet: UIViewController {
    private lazy var switchLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = .body
        label.text = "Require confirmation before dismissed"
        label.numberOfLines = 0
        return label
    }()

    private lazy var requireConfirmationOnDragSwitch: UISwitch = {
        let switchView = UISwitch(withAutoLayout: true)
        switchView.isOn = false
        return switchView
    }()

    private lazy var presentAllDraggableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present - everything draggable", for: .normal)
        button.addTarget(self, action: #selector(presentAllDraggableButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var presentNavBarDraggableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present - navBar draggable", for: .normal)
        button.addTarget(self, action: #selector(presentNavBarDraggableButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var presentTopAreaDraggableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present - topArea draggable", for: .normal)
        button.addTarget(self, action: #selector(presentTopAreaDraggableButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var presentCustomDraggableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present - custom draggable", for: .normal)
        button.addTarget(self, action: #selector(presentCustomDraggableButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var presentTableViewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present - table view", for: .normal)
        button.addTarget(self, action: #selector(presentTableView), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var bottomSheet: BottomSheet?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryBackground

        let stackView = UIStackView(axis: .vertical, spacing: .spacingM, alignment: .center)
        let firstRow = UIStackView(axis: .horizontal, spacing: .spacingS, distribution: .equalCentering)
        firstRow.addArrangedSubviews([
            switchLabel,
            requireConfirmationOnDragSwitch
        ])
        stackView.addArrangedSubviews([
            firstRow,
            presentAllDraggableButton,
            presentNavBarDraggableButton,
            presentTopAreaDraggableButton,
            presentCustomDraggableButton,
            presentTableViewButton
        ])
        view.addSubview(stackView)
        stackView.anchorToBottomSafeArea(margin: .spacingM)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleDoubleTap() {
        State.lastSelectedIndexPath = nil
        dismiss(animated: true)
    }

    @objc private func presentAllDraggableButtonPressed() {
        let rootController = BottomSheetExampleViewController()
        rootController.delegate = self
        let bottomSheet = BottomSheet(rootViewController: rootController, height: BottomSheetHeight.expanded, draggableArea: .everything)
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet
    }

    @objc private func presentNavBarDraggableButtonPressed() {
        let rootController = BottomSheetExampleViewController()
        rootController.delegate = self
        rootController.title = "👆😎👇"

        let navigationController = NavigationController(rootViewController: rootController)
        navigationController.navigationBar.isTranslucent = false

        let bottomSheet = BottomSheet(rootViewController: navigationController, draggableArea: .navigationBar)
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet
    }

    @objc private func presentTopAreaDraggableButtonPressed() {
        let rootController = BottomSheetExampleViewController()
        rootController.delegate = self
        rootController.title = "👆😎👇"

        let navigationController = NavigationController(rootViewController: rootController)
        navigationController.navigationBar.isTranslucent = false

        // Set draggable height to height of navBar.
        let draggableAreaHeight = navigationController.navigationBar.bounds.height
        let bottomSheet = BottomSheet(rootViewController: navigationController, draggableArea: .topArea(height: draggableAreaHeight))
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet
    }

    @objc private func presentCustomDraggableButtonPressed() {
        let rootController = BottomSheetExampleViewController(showDraggableLabel: true)
        rootController.delegate = self
        let bottomSheet = BottomSheet(rootViewController: rootController, draggableArea: .customRect(rootController.draggableLabelFrame))
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet
    }

    @objc private func presentTableView() {
        let bottomSheet = BottomSheet(view: PinBasicTableView(), height: BottomSheetHeight.compact(300), draggableArea: .everything)
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet
    }
}

extension PinViewControllerBottomSheet: RootViewControllerDelegate {
    func rootViewControllerDidPressExpandButton(_ controller: BottomSheetExampleViewController) {
        bottomSheet?.state = .expanded
    }

    func rootViewControllerDidPressCompactButton(_ controller: BottomSheetExampleViewController) {
        bottomSheet?.state = .compact
    }

    func rootViewControllerDidPressDismissButton(_ controller: BottomSheetExampleViewController) {
        bottomSheet?.state = .dismissed
    }
}

extension PinViewControllerBottomSheet: BottomSheetDelegate {
    func bottomSheetShouldDismiss(_ bottomSheet: BottomSheet) -> Bool {
        return !requireConfirmationOnDragSwitch.isOn
    }

    func bottomSheetDidCancelDismiss(_ bottomSheet: BottomSheet) {
        let alertStyle: UIAlertController.Style = UITraitCollection.isHorizontalSizeClassRegular ? .alert : .actionSheet

        let alertController = UIAlertController(title: "Dismiss?",
                                                message: "Confirmation required",
                                                preferredStyle: alertStyle)
        let cancelAction = UIAlertAction(title: "Don't dismiss", style: .cancel, handler: nil)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: { _ in
            bottomSheet.state = .dismissed
        })

        alertController.addAction(dismissAction)
        alertController.addAction(cancelAction)

        bottomSheet.present(alertController, animated: true)
    }

    func bottomSheet(_ bottomSheet: BottomSheet, willDismissBy action: BottomSheetDismissAction) {
    }

    func bottomSheet(_ bottomSheet: BottomSheet, didDismissBy action: BottomSheetDismissAction) {
    }
}

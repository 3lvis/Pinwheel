import UIKit

protocol RootViewControllerDelegate: AnyObject {
    func rootViewControllerDidPressExpandButton(_ controller: BottomSheetExampleViewController)
    func rootViewControllerDidPressCompactButton(_ controller: BottomSheetExampleViewController)
    func rootViewControllerDidPressDismissButton(_ controller: BottomSheetExampleViewController)
}

class BottomSheetExampleViewController: UIViewController {

    // MARK: - Public properties

    weak var delegate: RootViewControllerDelegate?
    var draggableLabelFrame: CGRect {
        return CGRect(
            origin: CGPoint(x: 0, y: 150),
            size: CGSize(width: view.frame.width, height: 44)
        )
    }

    // MARK: - Private properties

    private let showDraggableLabel: Bool

    private lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Expand", for: .normal)
        button.addTarget(self, action: #selector(expandButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var compactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Compact", for: .normal)
        button.addTarget(self, action: #selector(compactButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Dismiss", for: .normal)
        button.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var draggableLabel: UILabel = {
        let label = UILabel(frame: draggableLabelFrame)
        label.textAlignment = .center
        label.font = UIFont.body
        label.text = "👆😎👇"
        label.backgroundColor = .criticalBackground
        return label
    }()

    // MARK: - Init

    init(showDraggableLabel: Bool = false) {
        self.showDraggableLabel = showDraggableLabel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryBackground
        view.addSubview(expandButton)
        view.addSubview(compactButton)
        view.addSubview(dismissButton)

        if showDraggableLabel {
            view.addSubview(draggableLabel)
        }

        NSLayoutConstraint.activate([
            expandButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacingXL),
            expandButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacingXL),
            expandButton.topAnchor.constraint(equalTo: view.topAnchor, constant: .spacingS),

            compactButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacingXL),
            compactButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacingXL),
            compactButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),

            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .spacingXL),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.spacingXL),
            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.spacingXXL),
        ])
    }

    @objc private func expandButtonPressed() {
        delegate?.rootViewControllerDidPressExpandButton(self)
    }

    @objc private func compactButtonPressed() {
        delegate?.rootViewControllerDidPressCompactButton(self)
    }

    @objc private func dismissButtonPressed() {
        delegate?.rootViewControllerDidPressDismissButton(self)
    }
}

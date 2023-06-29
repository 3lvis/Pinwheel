import UIKit

/// Defines the way the designable controller will be dismissed
///
/// - dismissButton: Adds a floating dismiss button
/// - doubleTap: Double tapping dismisses the designable controller
/// - none: Lets you to define your own dismissing logic
public enum DismissType {
    case dismissButton
    case doubleTap
    case none
}

public struct ContainmentOptions: OptionSet {
    public let rawValue: Int8

    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }

    public static let navigationController = ContainmentOptions(rawValue: 1)
    public static let tabBarController = ContainmentOptions(rawValue: 1 << 1)
    public static let bottomSheet = ContainmentOptions(rawValue: 1 << 2)
    public static let none = ContainmentOptions(rawValue: 1 << 3)
    public static let all: ContainmentOptions = [.navigationController, .tabBarController, .bottomSheet]
}

/// Defines the container or containers to be used when presenting the designable view controller.
public protocol Containable {
    var containmentOptions: ContainmentOptions { get }
}

///  Container class for components. Wraps the UIView in a container to be displayed.
///  If the view conforms to the `Tweakable` protocol it will display a control to show additional options.
///  Usage: `BaseDesignableViewController<ColorDesignableView>()`
public class BaseDesignableViewController<View: UIView>: UIViewController, Containable {

    private(set) lazy var playgroundView: View = {
        let playgroundView = View(frame: view.frame)
        playgroundView.translatesAutoresizingMaskIntoConstraints = false
        playgroundView.backgroundColor = .primaryBackground
        return playgroundView
    }()

    /// Toast used to display information about how to dismiss a component designable
    private lazy var miniToastView: MiniToastView = {
        let view = MiniToastView()
        return view
    }()

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public private(set) var containmentOptions: ContainmentOptions
    private var dismissType: DismissType
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask = .all
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return preferredInterfaceOrientation
    }

    public init(dismissType: DismissType = .doubleTap,
                containmentOptions: ContainmentOptions = .none,
                supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
                constrainToTopSafeArea: Bool = true,
                constrainToBottomSafeArea: Bool = true) {
        self.dismissType = dismissType
        self.containmentOptions = containmentOptions
        self.preferredInterfaceOrientation = supportedInterfaceOrientations
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.constrainToTopSafeArea = constrainToTopSafeArea
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(playgroundView)
        view.backgroundColor = .primaryBackground

        let topAnchor = constrainToTopSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
        let bottomAnchor = constrainToBottomSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor

        NSLayoutConstraint.activate([
            playgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playgroundView.topAnchor.constraint(equalTo: topAnchor),
            playgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func didDoubleTap() {
        State.lastSelectedIndexPath = nil
        dismiss(animated: true, completion: nil)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch dismissType {
        case .dismissButton:
            let button = UIButton(type: .system)
            button.setTitle("Dismiss", for: .normal)
            button.addTarget(self, action: #selector(didDoubleTap), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -.spacingXXL)
            ])
        case .doubleTap:
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
        case .none:
            break
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // if State.shouldShowDismissInstructions {
            miniToastView.show(in: view, text: "Double tap to dismiss")
            State.shouldShowDismissInstructions = false
        // }
    }
}

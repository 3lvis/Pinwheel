import UIKit

/// Defines the way the pinwheel controller will be dismissed
///
/// - dismissButton: Adds a floating dismiss button
/// - doubleTap: Double tapping dismisses the pinwheel controller
/// - none: Lets you to define your own dismissing logic
public enum DismissType {
    case dismissButton
    case doubleTap
    case none
}

public enum PresentationStyle {
    case medium
    case large
    case fullscreen
}

///  Container class for components. Wraps the UIView in a container to be displayed.
///  If the view conforms to the `Tweakable` protocol it will display a control to show additional options.
///  Usage: `BasePinwheelViewController<ColorPinwheelView>()`
open class BasePinwheelViewController<View: UIView>: UIViewController {

    private(set) lazy var playgroundView: View = {
        let playgroundView = View(frame: view.frame)
        playgroundView.translatesAutoresizingMaskIntoConstraints = false
        playgroundView.backgroundColor = .primaryBackground
        return playgroundView
    }()

    /// Toast used to display information about how to dismiss a component pinwheel
    private lazy var miniToastView: MiniToastView = {
        let view = MiniToastView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    private var dismissType: DismissType
    private var presentationStyle: PresentationStyle
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask = .all
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return preferredInterfaceOrientation
    }

    public init(dismissType: DismissType = .dismissButton,
                presentationStyle: PresentationStyle = .fullscreen,
                supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
                constrainToTopSafeArea: Bool = true,
                constrainToBottomSafeArea: Bool = true) {
        self.dismissType = dismissType
        self.presentationStyle = presentationStyle
        self.preferredInterfaceOrientation = supportedInterfaceOrientations
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.constrainToTopSafeArea = constrainToTopSafeArea

        super.init(nibName: nil, bundle: nil)

        if #available(iOS 15.0, *) {
            switch presentationStyle {
            case .medium:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.medium()]
                sheetPresentationController?.preferredCornerRadius = 40
                sheetPresentationController?.prefersGrabberVisible = true
            case .large:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.large()]
                sheetPresentationController?.preferredCornerRadius = 40
                sheetPresentationController?.prefersGrabberVisible = true
            case .fullscreen:
                modalPresentationStyle = .fullScreen
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
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
            break
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

        if State.shouldShowDismissInstructions && dismissType == .doubleTap {
            miniToastView.show(in: view, text: "Double tap to dismiss")
            State.shouldShowDismissInstructions = false
        }
    }
}

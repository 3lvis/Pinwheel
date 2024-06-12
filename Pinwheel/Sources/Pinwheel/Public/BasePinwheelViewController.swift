import UIKit

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

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    private var presentationStyle: PresentationStyle
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask = .all
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return preferredInterfaceOrientation
    }

    public init(presentationStyle: PresentationStyle = .fullscreen,
                supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
                constrainToTopSafeArea: Bool = true,
                constrainToBottomSafeArea: Bool = true) {
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
                sheetPresentationController?.preferredCornerRadius = .spacingXL
                sheetPresentationController?.prefersGrabberVisible = true
            case .large:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.large()]
                sheetPresentationController?.preferredCornerRadius = .spacingXL
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
}

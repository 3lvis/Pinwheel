import SwiftUI
import UIKit

private let trayDimming: CGFloat = 0.35

extension UIScreen {
    var pinDisplayCornerRadius: CGFloat {
        (value(forKey: "_displayCornerRadius") as? CGFloat) ?? .radiusL
    }
}

final class PinTrayChassis: UIViewController {
    private let content: UIView
    private let dimming = UIView()
    private let displayRadius: CGFloat
    private let cardView: PinTrayCardView
    private let placement: PinTrayCardPlacement
    private var card: UIView { cardView.surface }
    private lazy var machine = PinTrayMachine(room: room)

    private struct Standing {
        let description: PinTray
        let contents: PinTrayContentsView

        func detach() { contents.detach() }
    }

    private lazy var accessoryView = PinTrayAccessoryView(in: self)

    private var standing: Standing?

    private let arriving: PinTray

    private static var opened = 0
    private let mark: String

    private func note(_ category: String, _ message: String) {
        PinwheelRecorder.note(category, "\(mark)  \(message)")
    }

    init(showing tray: PinTray, nestedIn displayCornerRadius: CGFloat, covering frame: CGRect) {
        let container = UIView(frame: frame)
        let card = PinTrayCardView(nestedIn: displayCornerRadius)
        content = container
        displayRadius = displayCornerRadius
        cardView = card
        placement = PinTrayCardPlacement(card: card, in: container)
        arriving = tray
        PinTrayChassis.opened += 1
        mark = "#\(PinTrayChassis.opened)"
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayChassis is made in code") }

    override func loadView() {
        content.translatesAutoresizingMaskIntoConstraints = false
        view = content
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard parent != nil, standing == nil else { return }
        placement.followTheKeyboard()
        view.layoutIfNeeded()
        present(arriving)
    }

    private var room: PinTrayGeometry.Room {
        PinTrayGeometry.Room(
            containerHeight: view.bounds.height,
            safeAreaTop: view.safeAreaInsets.top,
            safeAreaBottom: view.safeAreaInsets.bottom,
            displayCornerRadius: displayRadius
        )
    }

    private var measuredKeyboardHeight: CGFloat {
        max(0, view.bounds.maxY - view.keyboardLayoutGuide.layoutFrame.minY)
    }

    private func apply(_ reaction: PinTrayMachine.Reaction) {
        for effect in reaction.effects {
            switch effect {
            case .dismissKeyboard: view.endEditing(true)
            }
        }
        reaction.from.map { placement.place($0, alongside: dim(to: $0), animated: false) }
        note(
            "tray",
            "\(reaction.timeline)  card=\(Int(reaction.to.height)) inset=\(Int(reaction.to.bottomInset)) "
                + "translation=\(Int(reaction.to.translation))  phase=\(machine.phase) fills=\(machine.fills) "
                + "edits=\(machine.edits) keyboard=\(machine.keyboard)"
                + (reaction.effects.isEmpty ? "" : "  effects=\(reaction.effects)")
                + (reaction.dismisses ? "  dismisses" : "")
        )
        let finish: () -> Void = reaction.dismisses ? { [weak self] in self?.tearDown() } : {}
        switch reaction.timeline {
        case .immediate:
            placement.place(reaction.to, alongside: dim(to: reaction.to), animated: false, then: finish)
        case .carriedByKeyboard:
            placement.write(reaction.to)
            dim(to: reaction.to)()
            finish()
        case .spring(let bounce, let initialVelocity):
            placement.place(
                reaction.to,
                alongside: dim(to: reaction.to),
                animated: true,
                bounce: bounce,
                startingAt: initialVelocity,
                then: finish
            )
        case .matching(let timing):
            placement.place(reaction.to, alongside: dim(to: reaction.to), matching: timing, then: finish)
        }
    }

    private func tearDown() {
        accessoryView.detach()
        standing?.detach()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        note("navigation", "torn down")
        onGone()
        PinwheelRecorder.stopFollowing()
    }

    private func dim(to geometry: PinTrayGeometry) -> () -> Void {
        { self.dimming.alpha = geometry.dimming }
    }

    var cardHeight: CGFloat { cardView.bounds.height }
    var contentHeight: CGFloat { standing?.contents.bounds.height ?? 0 }
    var cardBottom: CGFloat { card.convert(card.bounds, to: view).maxY }
    var bottomCornerRadius: CGFloat { cardView.layer.cornerRadius }

    var onGone: () -> Void = {}
    var onExit: () -> Void = {}
    var motionIsReduced: Bool {
        get { machine.motionIsReduced }
        set { machine.motionIsReduced = newValue }
    }

    @objc private func motionPreferenceChanged() {
        machine.motionIsReduced = UIAccessibility.isReduceMotionEnabled
    }
    var depth = 0

    private var contentBottomInset: CGFloat {
        machine.geometry.contentBottomInset
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss()
        return true
    }

    private func build() {
        view.accessibilityViewIsModal = true

        dimming.frame = view.bounds
        dimming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimming.backgroundColor = UIColor.black.withAlphaComponent(trayDimming)
        dimming.alpha = 0
        view.insertSubview(dimming, belowSubview: cardView)
        dimming.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissFromBackground))
        )

        machine.motionIsReduced = UIAccessibility.isReduceMotionEnabled
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(motionPreferenceChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )

        for name in [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillHideNotification] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardAnnouncedItsMove),
                name: name,
                object: nil
            )
        }

        PinwheelRecorder.noteIfAlreadyFollowing("tray \(mark)")
        PinwheelRecorder.follow { [weak self] in
            guard let self else { return [] }
            let drawn = self.cardView.layer.presentation()
            let top = (drawn?.frame.minY ?? self.cardView.frame.minY) + (drawn?.transform.m42 ?? 0)
            let content = self.standing?.contents.layer.presentation()?.bounds.height
                ?? self.standing?.contents.bounds.height ?? 0
            return [
                ("cardTop", top),
                ("cardHeight", drawn?.bounds.height ?? 0),
                ("contentHeight", content),
                ("contentBottom", top + content),
                ("keyboard", self.measuredKeyboardHeight),
            ]
        }

        cardView.reporting = self
    }

    private var holdsFirstResponder: Bool {
        func search(_ view: UIView) -> Bool {
            view.isFirstResponder || view.subviews.contains(where: search)
        }
        return search(view)
    }

    @objc private func keyboardAnnouncedItsMove(_ notification: Notification) {
        guard
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        else { return }
        machine.keyboardTiming = PinTrayMachine.KeyboardTiming(duration: duration, curve: curve)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        apply(machine.handle(.roomChanged(room)))
        let measured = measuredKeyboardHeight
        guard machine.keyboard(measuring: measured) != machine.keyboard else { return }
        apply(machine.handle(.keyboardMeasured(measured)))
    }

    private func present(_ tray: PinTray) {
        note("navigation", "present")
        assemble(tray)
        apply(machine.handle(.presented(contentHeight: fittedHeight)))
    }

    func refresh(_ tray: PinTray) {
        guard let standing else { return }
        standing.contents.show(titleBar: titleBarLeaf(tray), content: inset(tray.content))
        settle()
    }

    func show(_ tray: PinTray, isPush: Bool) {
        note("navigation", isPush ? "push" : "pop")
        apply(machine.handle(.moveBegan(isPush: isPush)))

        let leaving = standing
        assemble(tray)
        standing?.contents.alpha = 0
        view.layoutIfNeeded()

        let zoom = CGAffineTransform(scaleX: machine.contentZoom, y: machine.contentZoom)
        standing?.contents.transform = isPush ? .identity : zoom

        UIView.animate(springDuration: trayResizeDuration, bounce: trayResizeBounce) {
            self.standing?.contents.alpha = 1
            self.standing?.contents.transform = .identity
            leaving?.contents.alpha = 0
            leaving?.contents.transform = isPush ? zoom : .identity
        } completion: { _ in
            leaving?.detach()
        }

        reportTheMoveOnceTheArrivingTrayHasMounted(isPush: isPush)
    }

    private func reportTheMoveOnceTheArrivingTrayHasMounted(isPush: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            apply(machine.handle(.moved(
                contentHeight: fittedHeight,
                edits: holdsFirstResponder,
                isPush: isPush
            )))
        }
    }

    func dismiss() {
        note("navigation", "dismiss")
        apply(machine.handle(.dismissed))
    }

    private func titleBarLeaf(_ tray: PinTray) -> AnyView {
        AnyView(
            PinTrayTitleBar(
                title: tray.title,
                isRoot: depth == 0,
                accessory: tray.titleAccessory,
                exit: { [weak self] in self?.onExit() }
            )
        )
    }

    private func inset(_ content: AnyView) -> AnyView {
        AnyView(content.padding(.horizontal, trayContentMargin))
    }

    func accessory(for tray: PinTray) -> PinTrayAccessory {
        if let floating = tray.floating { return .floating(inset(floating)) }
        guard let commit = tray.commit else { return .nothing }
        return .commitButton(inset(AnyView(
            PinButton(commit.title, action: commit.action)
                .style(.custom(text: .primaryBackground, background: .primaryText))
                .fullWidth()
        )))
    }

    private func assemble(_ tray: PinTray) {
        let contents = PinTrayContentsView(
            titleBar: titleBarLeaf(tray),
            content: inset(tray.content),
            in: self,
            reporting: self
        )

        contents.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contents)
        if accessoryView.superview == nil {
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(accessoryView)
            NSLayoutConstraint.activate([
                accessoryView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                accessoryView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                accessoryView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -accessoryInset),
            ])
        }
        card.bringSubviewToFront(accessoryView)
        NSLayoutConstraint.activate([
            contents.topAnchor.constraint(equalTo: card.topAnchor),
            contents.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            contents.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            contents.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        accessoryView.show(
            accessory(for: tray),
            replacing: standing != nil,
            over: trayResizeDuration
        )
        view.layoutIfNeeded()

        let width = view.bounds.width - trayMargin * 2
        let clearanceAboveAccessory = PinTrayGeometry.clearanceAboveAccessory(floats: tray.floating != nil)
        let accessoryHeight = accessoryView.height(fitting: width)
        contents.clearance = accessoryHeight > 0
            ? accessoryInset + accessoryHeight + clearanceAboveAccessory
            : contentBottomInset
        standing = Standing(description: tray, contents: contents)
        apply(machine.handle(.fillsReported(tray.detent == .filling)))
        note("tray", "assembled, measuring \(Int(fittedHeight))")
    }

    private var fittedHeight: CGFloat {
        guard let standing else { return 0 }
        return standing.contents.height(fitting: view.bounds.width - trayMargin * 2)
    }

    private var accessoryInset: CGFloat { contentBottomInset }

    func settle() {
        let measured = fittedHeight
        guard self.standing != nil, machine.resizes(to: measured) else { return }
        let standing = machine.geometry.height
        note("reported", "content measures \(Int(measured))  standing=\(Int(standing))")
        apply(machine.handle(.contentResized(measured)))
    }

    @objc private func dismissFromBackground() {
        note("navigation", "backdrop tapped")
        dismiss()
    }

    private func catchAnythingInFlight() {
        guard placement.isTravelling else { return }
        let caughtAt = placement.travelled
        placement.stopTravelling()
        apply(machine.handle(.caught(at: caughtAt)))
    }

    private func release(velocity: CGFloat) {
        apply(machine.handle(.released(velocity: velocity)))
    }
}

extension PinTrayChassis: PinTrayBodyCoordinating {
    var cardIsBeingPulled: Bool { machine.cardIsBeingPulled }

    func bodyWillBeginPulling() {
        catchAnythingInFlight()
    }

    func bodyWasPulledDown(by amount: CGFloat) {
        apply(machine.handle(.pulledFurther(amount)))
    }

    func bodyStoppedBeingPulled(velocity: CGFloat) {
        release(velocity: velocity)
    }
}

extension PinTrayChassis: PinTrayCardReporting {
    var pulledSoFar: CGFloat { machine.pulledSoFar }

    func cardWasTouched() {
        catchAnythingInFlight()
    }

    func cardWasDragged(to travelled: CGFloat) {
        apply(machine.handle(.dragged(travelled)))
    }

    func cardWasReleased(velocity: CGFloat) {
        release(velocity: velocity)
    }
}

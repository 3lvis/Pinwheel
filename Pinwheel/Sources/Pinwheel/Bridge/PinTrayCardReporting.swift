import CoreGraphics

@MainActor
protocol PinTrayCardReporting: AnyObject {
    var pulledSoFar: CGFloat { get }
    func cardWasTouched()
    func cardWasDragged(to travelled: CGFloat)
    func cardWasReleased(velocity: CGFloat)
}

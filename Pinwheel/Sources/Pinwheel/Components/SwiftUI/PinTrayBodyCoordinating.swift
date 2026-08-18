import CoreGraphics

@MainActor
protocol PinTrayBodyCoordinating: AnyObject {
    var cardIsBeingPulled: Bool { get }
    func bodyWillBeginPulling()
    func bodyWasPulledDown(by amount: CGFloat)
    func bodyStoppedBeingPulled(velocity: CGFloat)
}

@MainActor
final class PinTrayBodyReports: PinTrayBodyCoordinating {
    private(set) var pulls: [CGFloat] = []
    private(set) var releases: [CGFloat] = []
    var cardIsBeingPulled = false

    func bodyWillBeginPulling() {}
    func bodyWasPulledDown(by amount: CGFloat) { pulls.append(amount) }
    func bodyStoppedBeingPulled(velocity: CGFloat) { releases.append(velocity) }
}

import UIKit

class BottomSheetStateController {

    var frame: CGRect = .zero
    var state: BottomSheetState
    var compactHeight: CGFloat

    var targetPosition: CGPoint {
        return targetPosition(for: state)
    }

    var expandedPosition: CGPoint {
        var expanded = 0.0
        if let aView = view {
            expanded = aView.frame.height - aView.layoutMargins.top
        }
        return CGPoint(x: 0, y: frame.height - expanded)
    }

    var compactPosition: CGPoint {
        return CGPoint(x: 0, y: frame.height - compactHeight)
    }

    private let threshold: CGFloat = 75
    private var isExpandedByDefault = false
    var view: UIView?

    init(compactHeight: CGFloat, view: UIView?) {
        self.view = view
        var expanded = 0.0
        if let aView = view {
            expanded = aView.frame.height - aView.layoutMargins.top
        }
        self.compactHeight = compactHeight
        self.isExpandedByDefault = compactHeight == expanded
        self.state = isExpandedByDefault ? .expanded : .compact
    }

    func updateState(withTranslation translation: CGPoint) {
        state = nextState(forTranslation: translation, withCurrent: state, usingThreshold: threshold)
    }
}

private extension BottomSheetStateController {
    func nextState(forTranslation translation: CGPoint, withCurrent current: BottomSheetState, usingThreshold threshold: CGFloat) -> BottomSheetState {
        switch current {
        case .compact:
            if translation.y < -threshold {
                return .expanded
            } else if translation.y > threshold {
                return .dismissed
            }
        case .expanded:
            if translation.y > threshold {
                return isExpandedByDefault ? .dismissed : .compact
            }
        case .dismissed:
            if translation.y < -threshold {
                return .compact
            }
        }
        return current
    }

    func targetPosition(for state: BottomSheetState) -> CGPoint {
        switch state {
        case .compact:
            return compactPosition
        case .expanded:
            return expandedPosition
        case .dismissed:
            return CGPoint(x: 0, y: frame.height)
        }
    }
}

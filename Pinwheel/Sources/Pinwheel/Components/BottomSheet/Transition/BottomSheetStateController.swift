import UIKit

class BottomSheetStateController {
    var frame: CGRect = .zero
    var state: BottomSheetState = .compact

    var expandedPosition: CGPoint {
        var expanded = 0.0
        if let aView = view {
            expanded = aView.frame.height - aView.layoutMargins.top
        }
        return CGPoint(x: 0, y: frame.height - expanded)
    }

    private let threshold: CGFloat = 75
    var view: UIView?

    init(view: UIView?) {
        self.view = view
    }

    func updateState(withTranslation translation: CGPoint) {
        state = nextState(forTranslation: translation, withCurrent: state, usingThreshold: threshold)
    }

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
                return .compact
            }
        case .dismissed:
            if translation.y < -threshold {
                return .compact
            }
        }
        return current
    }

    func targetPosition(for state: BottomSheetState, height: BottomSheetHeight) -> CGPoint {
        switch state {
        case .compact:
            switch height {
            case .compact(let value):
                return CGPoint(x: 0, y: value)
            case .expanded:
                return expandedPosition
            }
        case .expanded:
            return expandedPosition
        case .dismissed:
            return CGPoint(x: 0, y: frame.height)
        }
    }
}

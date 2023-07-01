import UIKit

class BottomSheetStateController {

    var frame: CGRect = .zero
    var state: BottomSheetState
    var height: BottomSheetHeight

    var targetPosition: CGPoint {
        return targetPosition(for: state)
    }

    var expandedPosition: CGPoint {
        return CGPoint(x: 0, y: frame.height - height.expanded)
    }

    var compactPosition: CGPoint {
        return CGPoint(x: 0, y: frame.height - height.compact)
    }

    private let threshold: CGFloat = 75
    private var isExpandedByDefault = false

    init(height: BottomSheetHeight) {
        self.height = height
        self.isExpandedByDefault = height.compact == height.expanded
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

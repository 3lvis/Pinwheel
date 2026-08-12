import UIKit

public nonisolated extension UIFont {
    class var title: UIFont { themed { $0.title } }
    class var titleSemibold: UIFont { themed { $0.titleSemibold } }
    class var subtitle: UIFont { themed { $0.subtitle } }
    class var subtitleSemibold: UIFont { themed { $0.subtitleSemibold } }
    class var body: UIFont { themed { $0.body } }
    class var bodySemibold: UIFont { themed { $0.bodySemibold } }
    class var footnote: UIFont { themed { $0.footnote } }
    class var footnoteSemibold: UIFont { themed { $0.footnoteSemibold } }
    class var caption: UIFont { themed { $0.caption } }
    class var captionSemibold: UIFont { themed { $0.captionSemibold } }

    func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }

    // UIFont has no dynamic-provider counterpart to UIColor's, so this resolves once at the read.
    private static func themed(_ token: (FontProvider) -> UIFont) -> UIFont {
        token(UITraitCollection.current[PinwheelThemeTrait.self].fonts)
    }
}

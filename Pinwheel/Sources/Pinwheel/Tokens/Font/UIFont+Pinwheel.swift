import UIKit

nonisolated extension UIFont {
    public class var title: UIFont { themed { $0.title } }
    public class var titleSemibold: UIFont { themed { $0.titleSemibold } }
    public class var subtitle: UIFont { themed { $0.subtitle } }
    public class var subtitleSemibold: UIFont { themed { $0.subtitleSemibold } }
    public class var body: UIFont { themed { $0.body } }
    public class var bodySemibold: UIFont { themed { $0.bodySemibold } }
    public class var footnote: UIFont { themed { $0.footnote } }
    public class var footnoteSemibold: UIFont { themed { $0.footnoteSemibold } }
    public class var caption: UIFont { themed { $0.caption } }
    public class var captionSemibold: UIFont { themed { $0.captionSemibold } }

    public func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }

    // UIFont has no dynamic-provider counterpart to UIColor's, so this resolves once at the read.
    private static func themed(_ token: (PinwheelFontProvider) -> UIFont) -> UIFont {
        token(UITraitCollection.current[PinwheelThemeTrait.self].fonts)
    }
}

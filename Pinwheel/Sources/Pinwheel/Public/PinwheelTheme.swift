import SwiftUI
import UIKit

public enum PinwheelTheme {
    public enum Typography {
        public static var title: Font { Font(UIFont.title) }
        public static var subtitle: Font { Font(UIFont.subtitle) }
        public static var subtitleSemibold: Font { Font(UIFont.subtitleSemibold) }
        public static var body: Font { Font(UIFont.body) }
        public static var footnote: Font { Font(UIFont.footnote) }
        public static var caption: Font { Font(UIFont.caption) }
    }

    public enum Colors {
        public static var primaryText: Color { Color(uiColor: .primaryText) }
        public static var secondaryText: Color { Color(uiColor: .secondaryText) }
        public static var tertiaryText: Color { Color(uiColor: .tertiaryText) }
        public static var actionText: Color { Color(uiColor: .actionText) }
        public static var criticalText: Color { Color(uiColor: .criticalText) }

        public static var primaryBackground: Color { Color(uiColor: .primaryBackground) }
        public static var secondaryBackground: Color { Color(uiColor: .secondaryBackground) }
        public static var actionBackground: Color { Color(uiColor: .actionBackground) }
        public static var criticalBackground: Color { Color(uiColor: .criticalBackground) }
    }
}

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import PinwheelMacrosImpl

final class PinnableTests: XCTestCase {
    private let macros = [
        "Pinnable": PinnableMacro.self,
        "PinText": PinMarkerMacro.self,
        "PinTypography": PinMarkerMacro.self,
        "PinColor": PinMarkerMacro.self,
        "PinFill": PinMarkerMacro.self,
    ] as [String: Macro.Type]

    func testLabelGeneratesStyleDescriptor() {
        assertMacroExpansion(
            """
            @Pinnable("Label")
            struct PinLabel {
                @PinText let text: String
                @PinTypography var typography: PinTextStyle = .body
                @PinColor var color: TextColor = .primary
            }
            """,
            expandedSource: """
            struct PinLabel {
                let text: String
                var typography: PinTextStyle = .body
                var color: TextColor = .primary

                var pinnedStyle: PinComponentStyle {
                    PinComponentStyle(
                        name: "Label",
                        text: text,
                        textStyle: typography,
                        textColorTokenName: color.captureTextColorToken,
                        fillTokenName: nil,
                        cornerRadius: nil,
                        centersText: false
                    )
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testButtonPassesConstantsAndFill() {
        assertMacroExpansion(
            """
            @Pinnable("Button", cornerRadius: .spacingM, centersText: true)
            struct PinButton {
                @PinText let title: String?
                @PinTypography var typography: PinTextStyle = .subtitleSemibold
                @PinFill var style: Style = .primary
            }
            """,
            expandedSource: """
            struct PinButton {
                let title: String?
                var typography: PinTextStyle = .subtitleSemibold
                var style: Style = .primary

                var pinnedStyle: PinComponentStyle {
                    PinComponentStyle(
                        name: "Button",
                        text: title,
                        textStyle: typography,
                        textColorTokenName: nil,
                        fillTokenName: style.captureFillToken,
                        cornerRadius: .spacingM,
                        centersText: true
                    )
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }
}

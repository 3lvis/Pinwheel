import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PinwheelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [PinnableMacro.self, PinMarkerMacro.self]
}

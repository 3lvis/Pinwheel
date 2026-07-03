import SwiftSyntax
import SwiftSyntaxMacros

/// Marker attributes (`@PinText`, `@PinTypography`, …) generate nothing; `@Pinnable` reads
/// them off each property. Same role as SwiftSync's `@RemoteKey`/`@NotExport`.
public struct PinMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

public struct PinnableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        guard let nameExpression = arguments?.first(where: { $0.label == nil })?.expression,
              let name = stringLiteralText(nameExpression) else {
            return []
        }
        let cornerRadius = labeledArgument("cornerRadius", in: arguments)?.trimmedDescription ?? "nil"
        let centersText = labeledArgument("centersText", in: arguments)?.trimmedDescription ?? "false"

        // Read the marked properties off the declaration (SwiftSync's member-walk pattern).
        var text = "nil"
        var textStyle = "nil"
        var textColorTokenName = "nil"
        var fillTokenName = "nil"
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  let pattern = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let property = pattern.identifier.text
            for marker in markerNames(of: variable) {
                switch marker {
                case "PinText": text = property
                case "PinTypography": textStyle = property
                case "PinColor": textColorTokenName = "\(property).captureTextColorToken"
                case "PinFill": fillTokenName = "\(property).captureFillToken"
                default: break
                }
            }
        }

        return ["""
            var pinnedStyle: PinComponentStyle {
                PinComponentStyle(
                    name: \(literal: name),
                    text: \(raw: text),
                    textStyle: \(raw: textStyle),
                    textColorTokenName: \(raw: textColorTokenName),
                    fillTokenName: \(raw: fillTokenName),
                    cornerRadius: \(raw: cornerRadius),
                    centersText: \(raw: centersText)
                )
            }
            """]
    }
}

private func stringLiteralText(_ expression: ExprSyntax) -> String? {
    expression.as(StringLiteralExprSyntax.self)?
        .segments.first?.as(StringSegmentSyntax.self)?.content.text
}

private func labeledArgument(_ label: String, in arguments: LabeledExprListSyntax?) -> ExprSyntax? {
    arguments?.first(where: { $0.label?.text == label })?.expression
}

private func markerNames(of variable: VariableDeclSyntax) -> [String] {
    variable.attributes.compactMap { $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription }
}

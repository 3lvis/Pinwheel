import CoreGraphics

/// Generates a component's Figma-capture style descriptor from its declaration, so authors
/// annotate the pieces instead of hand-writing the `.pinCaptured(...)` mapping. Mirrors
/// SwiftSync's `@Syncable` + peer-attribute model.
@attached(member, names: named(pinnedStyle))
public macro Pinnable(_ name: String, cornerRadius: CGFloat? = nil, centersText: Bool = false)
    = #externalMacro(module: "PinwheelMacrosImpl", type: "PinnableMacro")

/// Marks the property whose value is the component's text.
@attached(peer) public macro PinText() = #externalMacro(module: "PinwheelMacrosImpl", type: "PinMarkerMacro")

/// Marks the property holding the component's `PinTextStyle`.
@attached(peer) public macro PinTypography() = #externalMacro(module: "PinwheelMacrosImpl", type: "PinMarkerMacro")

/// Marks the property whose token drives the text color (a `PinCaptureToken`).
@attached(peer) public macro PinColor() = #externalMacro(module: "PinwheelMacrosImpl", type: "PinMarkerMacro")

/// Marks the property whose token drives the fill (a `PinCaptureToken`).
@attached(peer) public macro PinFill() = #externalMacro(module: "PinwheelMacrosImpl", type: "PinMarkerMacro")

/// The content state shared by the components that present loading / empty /
/// failed placeholders — `PinStateView` (as an overlay) and `PinList` (gating
/// its rows). Promoted to a top-level type, like `PinTextStyle`, so neither
/// component "owns" the vocabulary the other reuses.
///
/// `.loaded` carries no copy: it means "show your content" — `PinStateView`
/// renders nothing, `PinList` shows its rows.
public enum PinState: Equatable {
    case loading(title: String, subtitle: String)
    case loaded
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

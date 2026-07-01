/// `.loaded` means "show your content": `PinStateView` renders nothing, `PinList` shows its rows.
public enum PinState: Equatable {
    case loading(title: String, subtitle: String)
    case loaded
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

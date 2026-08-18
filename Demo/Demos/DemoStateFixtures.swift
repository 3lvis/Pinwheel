import Pinwheel

enum DemoStateFixture {
    static let loadingTitle = "Loading..."
    static let loadingSubtitle = "Please wait while we fetch your details."
    static let emptyTitle = "Ready to Move?"
    static let emptySubtitle = "Kick things off with your first booking."
    static let failedTitle = "Oops!"
    static let failedSubtitle = "We couldn't load your bookings."
    static let retryActionTitle = "Retry"

    static let loading = PinState.loading(title: loadingTitle, subtitle: loadingSubtitle)
    static let empty = PinState.empty(title: emptyTitle, subtitle: emptySubtitle)
    static let failed = PinState.failed(title: failedTitle, subtitle: failedSubtitle, actionTitle: retryActionTitle)

    static let states: [(title: String, state: PinState)] = [
        ("Loading", loading),
        ("Loaded", .loaded),
        ("Empty", empty),
        ("Failed", failed),
    ]

    static let viewStates: [UIPinStateViewState] = [
        .loading(title: loadingTitle, subtitle: loadingSubtitle),
        .loaded,
        .empty(title: emptyTitle, subtitle: emptySubtitle),
        .failed(title: failedTitle, subtitle: failedSubtitle, actionTitle: retryActionTitle)
    ]

    @MainActor
    static var tableStates: [UIPinTableViewState] {
        [
            .loading(title: loadingTitle, subtitle: loadingSubtitle),
            .loaded([UIPinTextTableViewItem(title: "Only value")]),
            .empty(title: emptyTitle, subtitle: emptySubtitle),
            .failed(title: failedTitle, subtitle: failedSubtitle, actionTitle: retryActionTitle)
        ]
    }

    static let loadingIndex = 0
    static let loadedIndex = 1
    static let emptyIndex = 2

    static var titles: [String] { states.map(\.title) }

    static func state(at index: Int) -> PinState { states[index].state }

    static func viewState(at index: Int) -> UIPinStateViewState { viewStates[index] }

    @MainActor
    static func tableState(at index: Int) -> UIPinTableViewState { tableStates[index] }
}

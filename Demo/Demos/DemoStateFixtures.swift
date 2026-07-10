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
}

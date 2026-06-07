import SwiftUI
import UIKit
import Pinwheel

@main
struct DemoApp: App {
    init() {
        Config.colorProvider = DemoColorProvider()
        Config.fontProvider = DemoFontProvider()
    }

    var body: some Scene {
        WindowGroup {
            PinwheelCatalog {
                PinwheelSection("DNA", id: "dna") {
                    PinwheelItem("Font", id: "font") {
                        PinSwiftUIFont()
                    }

                    PinwheelItem("Color", id: "color") {
                        PinSwiftUIColor()
                    }

                    PinwheelItem("Spacing", id: "spacing") {
                        PinSwiftUISpacing()
                    }
                }

                PinwheelSection("Components", id: "components") {
                    PinwheelItem("Label", id: "label") {
                        PinSwiftUILabel()
                    }

                    PinwheelItem("Tweakable", id: "tweakable") {
                        PinSwiftUITweakable()
                    }

                    PinwheelItem("FullscreenView", id: "fullscreen-view") {
                        PinSwiftUIFullscreenView()
                    }

                    PinwheelItem("Button", id: "button") {
                        PinSwiftUIButton()
                    }

                    PinwheelItem("StateView", id: "state-view") {
                        PinSwiftUIStateView()
                    }
                }

                PinwheelSection("Reciclable", id: "reciclable") {
                    PinwheelItem("TableView", id: "table-view", presentation: .medium) {
                        PinSwiftUITableView()
                    }
                }

                PinwheelSection("UIKit", id: "uikit") {
                    PinwheelItem("UIKit Font", id: "uikit-font", view: PinFont.self)
                    PinwheelItem("UIKit Color", id: "uikit-color", view: PinColor.self)
                    PinwheelItem("UIKit Spacing", id: "uikit-spacing", view: PinSpacing.self)
                    PinwheelItem("UIKit Label", id: "uikit-label", view: PinLabel.self)
                    PinwheelItem("UIKit Tweakable", id: "uikit-tweakable", view: PinTweakable.self)
                    PinwheelItem("UIKit FullscreenView", id: "uikit-fullscreen-view", view: PinFullscreenView.self)
                    PinwheelItem("UIKit Button", id: "uikit-button", view: PinButton.self)
                    PinwheelItem("UIKit StateView", id: "uikit-state-view", view: PinStateView.self)
                    PinwheelItem("UIKit TableView", id: "uikit-table-view", presentation: .medium, view: PinTableView.self)
                }
            }
        }
    }
}

private struct PinSwiftUIFont: SwiftUI.View {
    private let fonts: [(String, Font)] = [
        ("Title", .title),
        ("Subtitle", .title3),
        ("Body", .body),
        ("Footnote", .footnote),
        ("Caption", .caption),
        ("Title Semibold", .title.weight(.semibold)),
        ("Subtitle Semibold", .title3.weight(.semibold)),
        ("Body Semibold", .body.weight(.semibold)),
        ("Footnote Semibold", .footnote.weight(.semibold)),
        ("Caption Semibold", .caption.weight(.semibold))
    ]

    var body: some SwiftUI.View {
        List(fonts, id: \.0) { title, font in
            Text(title)
                .font(font)
                .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                .listRowBackground(SwiftUI.Color(uiColor: .primaryBackground))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

private struct PinSwiftUIColor: SwiftUI.View {
    private let colors: [(String, UIColor)] = [
        ("Primary Text", .primaryText),
        ("Secondary Text", .secondaryText),
        ("Tertiary Text", .tertiaryText),
        ("Action Text", .actionText),
        ("Critical Text", .criticalText),
        ("Primary Background", .primaryBackground),
        ("Secondary Background", .secondaryBackground),
        ("Action Background", .actionBackground),
        ("Critical Background", .criticalBackground)
    ]

    var body: some SwiftUI.View {
        List(colors, id: \.0) { title, color in
            HStack {
                Text(title)
                    .foregroundStyle(.black)
                Text(title)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(SwiftUI.Color(uiColor: color))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

private struct PinSwiftUISpacing: SwiftUI.View {
    private let spacings: [(String, CGFloat)] = [
        ("spacingXXS", .spacingXXS),
        ("spacingXS", .spacingXS),
        ("spacingXM", .spacingXM),
        ("spacingS", .spacingS),
        ("spacingM", .spacingM),
        ("spacingL", .spacingL),
        ("spacingXL", .spacingXL),
        ("spacingXXL", .spacingXXL)
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingXXL) {
                ForEach(spacings, id: \.0) { title, spacing in
                    Text("\(title) \(Int(spacing))")
                        .font(.body)
                        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingS)
                        .background(SwiftUI.Color(uiColor: .tertiaryText))
                        .padding(.horizontal, spacing)
                }
            }
            .padding(.top, .spacingXXL)
        }
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

private struct PinSwiftUILabel: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            Text("Title").font(.title)
            Text("Subtitle").font(.title3)
            Text("Body").font(.body)
            Text("Footnote").font(.footnote)
            Text("Caption").font(.caption)
        }
        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingL)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

private struct PinSwiftUITweakable: SwiftUI.View {
    @SwiftUI.State private var selection = "Tap the settings button and choose an option."
    @SwiftUI.State private var isOn = false

    var body: some SwiftUI.View {
        Text(selection)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
            .padding(.spacingXXL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SwiftUI.Color(uiColor: .primaryBackground))
            .pinwheelTweaks {
                PinwheelTweak("Option 1") {
                    selection = "Chosen Option 1"
                }

                PinwheelTweak("Option 2", description: "Description 2") {
                    selection = "Chosen Option 2"
                }

                PinwheelTweak("Option 3", description: "Toggle-backed option", isOn: $isOn)
            }
            .onChange(of: isOn) { value in
                selection = "Option 3 is \(value ? "on" : "off")"
            }
    }
}

private struct PinSwiftUIFullscreenView: SwiftUI.View {
    @SwiftUI.State private var text = ""

    var body: some SwiftUI.View {
        VStack(spacing: .spacingM) {
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(SwiftUI.Color(uiColor: .secondaryBackground))
                .frame(minHeight: 180)

            Spacer()

            HStack {
                Text("Left Label")
                Spacer()
                Text("Right Label")
            }
            .font(.body)
            .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        }
        .padding(.spacingM)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

private struct PinSwiftUIButton: SwiftUI.View {
    @SwiftUI.State private var isLoading = false
    @SwiftUI.State private var isDisabled = false

    var body: some SwiftUI.View {
        VStack(spacing: 16) {
            SwiftUI.Button {
                isLoading.toggle()
            } label: {
                SwiftUI.Label(isLoading ? "Saving" : "Save", systemImage: isLoading ? "clock" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDisabled)

            SwiftUI.Button("Secondary") {
            }
            .buttonStyle(.bordered)
            .disabled(isDisabled)

            SwiftUI.Button("Destructive", role: .destructive) {
            }
            .buttonStyle(.bordered)
            .disabled(isDisabled)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}

private struct PinSwiftUIStateView: SwiftUI.View {
    private enum StateKind: String {
        case loading
        case loaded
        case empty
        case failed
    }

    @SwiftUI.State private var state: StateKind = .loaded

    var body: some SwiftUI.View {
        VStack(spacing: .spacingM) {
            switch state {
            case .loading:
                ProgressView("Loading...")
                    .font(.body)
            case .loaded:
                Text("Loaded")
                    .font(.title.bold())
            case .empty:
                Text("Ready to Move?")
                    .font(.title.bold())
                Text("Kick things off with your first booking.")
                    .font(.body)
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
            case .failed:
                Text("Oops!")
                    .font(.title.bold())
                Text("We couldn't load your bookings.")
                    .font(.body)
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                SwiftUI.Button("Retry") {
                    state = .loading
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.spacingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = .loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = .empty }
            PinwheelTweak("Failed") { state = .failed }
        }
    }
}

private struct PinSwiftUITableView: SwiftUI.View {
    @SwiftUI.State private var state = "loaded"
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        List {
            switch state {
            case "loading":
                ProgressView("Loading...")
            case "empty":
                ContentUnavailableView("Ready to Move?", systemImage: "tray", description: Text("Kick things off with your first booking."))
            case "failed":
                ContentUnavailableView {
                    Label("Oops!", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("We couldn't load your bookings.")
                } actions: {
                    SwiftUI.Button("Retry") {
                        state = "loading"
                    }
                }
            default:
                Text("Only title")
                VStack(alignment: .leading) {
                    Text("Title and subtitle")
                    Text("subtitle")
                        .font(.caption)
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Title, subtitle and detail")
                        Text("subtitle")
                            .font(.caption)
                            .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                    }
                    Spacer()
                    Text("Detail text")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                HStack {
                    Text("Has chevron")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                Text("Is disabled")
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                Toggle("Off", isOn: $off)
                Toggle("On", isOn: $on)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = "loading" }
            PinwheelTweak("Loaded") { state = "loaded" }
            PinwheelTweak("Empty") { state = "empty" }
            PinwheelTweak("Failed") { state = "failed" }
        }
    }
}

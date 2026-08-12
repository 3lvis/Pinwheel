import SwiftUI

struct PinwheelSettingsView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    @SwiftUI.Binding var selectedDeviceIndex: Int?

    @Environment(PinwheelChrome.self) private var chrome
    @Environment(\.pinwheelTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            List {
                displayRows
                if !tweaks.isEmpty {
                    SwiftUI.Section {
                        ForEach(tweaks) { tweak in
                            tweakRow(tweak)
                                .listRowBackground(Color.primaryBackground)
                        }
                    } header: {
                        PinLabel("Options").font(.caption).color(.secondary).textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PinLabel("Settings").font(.subtitleSemibold)
                        .accessibilityIdentifier("pinwheel.settings.theme.\(theme.name)")
                }
            }
        }
    }

    @ViewBuilder
    private var displayRows: some SwiftUI.View {
        if chrome.themes.count > 1 {
            SettingsRow(title: "Theme", value: chrome.theme.name) {
                themePicker
            }
            .accessibilityIdentifier("pinwheel.theme")
        }
        SettingsRow(title: "Appearance", value: selectedAppearance.title) {
            appearancePicker
        }
        .accessibilityIdentifier("pinwheel.appearance")
        SettingsRow(title: "Device", value: simulatedDeviceTitle) {
            PinwheelDeviceList(selectedIndex: $selectedDeviceIndex)
        }
        .accessibilityIdentifier("pinwheel.device")
    }

    private var selectedAppearance: PinwheelAppearance {
        PinwheelAppearance.allCases.first { $0.colorScheme == chrome.colorScheme } ?? .system
    }

    private var simulatedDeviceTitle: String {
        chrome.simulatedDevice?.title ?? "This device"
    }


    private var themePicker: some SwiftUI.View {
        PickerList(title: "Theme") {
            ForEach(chrome.themes) { theme in
                ThemeSampleRow(theme: theme, isSelected: theme == chrome.theme) {
                    chrome.selectTheme(theme)
                }
                .listRowSeparatorTint(.secondaryBackground)
                .listRowBackground(Color.primaryBackground)
            }
        }
    }

    private var appearancePicker: some SwiftUI.View {
        PickerList(title: "Appearance") {
            ForEach(PinwheelAppearance.allCases) { appearance in
                PickerRow(title: appearance.title, isSelected: appearance == selectedAppearance) {
                    chrome.colorScheme = appearance.colorScheme
                }
                .accessibilityIdentifier("pinwheel.appearance.\(appearance.rawValue)")
                .listRowSeparatorTint(.secondaryBackground)
                .listRowBackground(Color.primaryBackground)
            }
        }
    }

    @ViewBuilder
    private func tweakRow(_ tweak: PinwheelTweak) -> some SwiftUI.View {
        switch tweak.control {
        case .action(let action):
            SwiftUI.Button {
                action()
                dismiss()
            } label: {
                tweakLabels(tweak)
            }
            .buttonStyle(.plain)
        case .toggle(let isOn):
            Toggle(isOn: isOn) { tweakLabels(tweak) }
                .tint(.actionText)
        }
    }

    private func tweakLabels(_ tweak: PinwheelTweak) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            PinLabel(tweak.title)
            if let description = tweak.description {
                PinLabel(description).font(.caption).color(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct SettingsRow<Destination: SwiftUI.View>: SwiftUI.View {
    let title: String
    let value: String
    @ViewBuilder let destination: () -> Destination

    var body: some SwiftUI.View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                PinLabel(title)
                Spacer()
                PinLabel(value).color(.secondary)
            }
        }
        .listRowSeparatorTint(.secondaryBackground)
        .listRowBackground(Color.primaryBackground)
    }
}

// Not a `List`: a scroll view takes all the height it is offered, so measuring one reports the
// sheet's height back to itself and the fitted detent silently does nothing.
struct PickerList<Content: SwiftUI.View>: SwiftUI.View {
    let title: String
    @ViewBuilder let content: () -> Content

    @SwiftUI.State private var contentHeight: CGFloat = 0
    @SwiftUI.State private var safeAreaBottom: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider()
                    // A Divider is a 0.33pt hairline by default, which disappears on a light surface.
                    .frame(height: 1)
                    .overlay(Color.secondaryBackground)
                    .padding(.horizontal, .spacingXL)
                content()
                PinButton("Done") { dismiss() }
                    .style(.primary)
                    .fullWidth()
                    .padding(.horizontal, .spacingXL)
                    .padding(.top, .spacingXL)
            }
            .padding(.bottom, .spacingXL)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.primaryBackground)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { safeAreaBottom = $0 }
        .presentationDragIndicator(.hidden)
        // A sheet adds its bottom safe-area inset on top of the detent, so asking for the content's
        // height yields a sheet that much taller and an empty strip under the content.
        .presentationDetents([.height(max(contentHeight - safeAreaBottom, 0)), .large])
    }

    private var header: some SwiftUI.View {
        HStack {
            PinLabel(title).font(.titleSemibold)
            Spacer()
            SwiftUI.Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(PinTextStyle.subtitleSemibold.font(in: theme))
            }
            .tint(.primaryText)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, .spacingXL)
        .padding(.top, .spacingXL)
        .padding(.bottom, .spacingM)
    }

    @Environment(\.pinwheelTheme) private var theme
}

enum PinwheelAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalizingFirstLetter }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }
}

struct PickerRow: SwiftUI.View {
    let title: String
    let isSelected: Bool
    let select: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: select) {
            HStack {
                PinLabel(title).color(isSelected ? .action : .primary)
                Spacer()
                PickerRadio(isSelected: isSelected)
            }
            .padding(.horizontal, .spacingXL)
            .padding(.vertical, .spacingM)
            .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ThemeSampleRow: SwiftUI.View {
    let theme: PinwheelTheme
    let isSelected: Bool
    let select: () -> Void

    var body: some SwiftUI.View {
        PickerRow(title: theme.name, isSelected: isSelected, select: select)
            .environment(\.pinwheelTheme, theme)
            .accessibilityIdentifier("pinwheel.theme.\(theme.id)")
    }
}

struct PinwheelDeviceList: SwiftUI.View {
    @SwiftUI.Binding var selectedIndex: Int?

    private let devices = Device.all

    var body: some SwiftUI.View {
        PickerList(title: "Device") {
            ForEach(Array(devices.enumerated()), id: \.offset) { index, device in
                PickerRow(title: device.title, isSelected: isSelected(index, device)) {
                    selectedIndex = index
                }
                .disabled(!device.isEnabled)
                .listRowSeparatorTint(.secondaryBackground)
                .listRowBackground(Color.primaryBackground)
            }
        }
    }

    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

private struct PickerRadio: SwiftUI.View {
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = .spacingXL

    var body: some SwiftUI.View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Color.actionText : Color.tertiaryText, lineWidth: 2)
            if isSelected {
                Circle()
                    .fill(Color.actionText)
                    .padding(5)
            }
        }
        .frame(width: size, height: size)
    }
}


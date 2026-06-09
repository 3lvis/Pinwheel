import SwiftUI

struct PinwheelPlayground: SwiftUI.View {
    let item: PinwheelItem
    let selection: PinwheelSelection
    let onClose: () -> Void

    /// Preview mode (deep-link). When set, the component's tweak titles are
    /// dumped for tooling and `autoApplyTweak` is applied once it's available.
    var previewMode: Bool = false
    /// Title of a tweak to auto-apply on launch, so the preview lands directly
    /// on a variant (e.g. the StateView "Failed" state) without tapping.
    var autoApplyTweak: String?

    @SwiftUI.State private var didApplyPreviewTweak = false
    @SwiftUI.State private var didDumpPreviewTweaks = false

    @Environment(PinwheelChrome.self) private var chrome

    var body: some SwiftUI.View {
        @Bindable var chrome = chrome
        return GeometryReader { geometry in
            content(in: geometry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SwiftUI.Color(uiColor: .primaryBackground).ignoresSafeArea())
                .onAppear {
                    chrome.selectedDeviceIndex = PinwheelStateStore.selectedDeviceIndex(for: selection)
                    chrome.onClose = onClose
                    chrome.isPresentingItem = true
                }
                .onChange(of: chrome.selectedDeviceIndex) { _, newValue in
                    PinwheelStateStore.setSelectedDeviceIndex(newValue, for: selection)
                }
                .onDisappear {
                    chrome.isPresentingItem = false
                    chrome.showsSettings = false
                    chrome.showsDeviceList = false
                    chrome.selectedDeviceIndex = nil
                    chrome.tweaks = []
                    chrome.onClose = nil
                }
                .sheet(isPresented: $chrome.showsSettings) {
                    PinwheelSettingsView(
                        tweaks: chrome.tweaks,
                        selectedDeviceIndex: $chrome.selectedDeviceIndex,
                        startOnDeviceList: chrome.showsDeviceList
                    )
                    .presentationDetents([.medium, .large])
                }
        }
    }

    private var selectedDevice: Device? {
        return chrome.selectedDeviceIndex.flatMap { Device.all[safe: $0] }
    }

    private func content(in geometry: GeometryProxy) -> some SwiftUI.View {
        let device = selectedDevice
        let size = device?.frame.size ?? geometry.size
        let origin = originForDevice(device, in: geometry.size)

        return PinwheelHostedItem(item: item)
            .environment(\.horizontalSizeClass, horizontalSizeClass(for: device))
            .environment(\.verticalSizeClass, verticalSizeClass(for: device))
            .background(SwiftUI.Color(uiColor: .primaryBackground))
            .frame(width: size.width, height: size.height, alignment: .center)
            .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
            .clipped()
            .onPreferenceChange(PinwheelTweaksPreferenceKey.self) { tweaks in
                chrome.tweaks = tweaks
                handlePreviewTweaks(tweaks)
            }
    }

    private func handlePreviewTweaks(_ tweaks: [PinwheelTweak]) {
        guard previewMode else { return }

        if !didDumpPreviewTweaks {
            didDumpPreviewTweaks = true
            PinwheelPreviewTweakDump.write(tweaks.map(\.title))
        }

        guard let target = autoApplyTweak, !didApplyPreviewTweak,
              let tweak = tweaks.first(where: { $0.title == target }) else {
            return
        }
        didApplyPreviewTweak = true
        // Defer past the current view update before mutating the example's state.
        DispatchQueue.main.async {
            tweak.applyAsPreviewVariant()
        }
    }

    private func originForDevice(_ device: Device?, in containerSize: CGSize) -> CGPoint {
        guard let device else { return .zero }

        switch device.autoresizingMask {
        case let mask where mask.contains(.flexibleHeight) && !mask.contains(.flexibleLeftMargin):
            return CGPoint(x: 0, y: max((containerSize.height - device.frame.height) / 2, 0))
        default:
            return CGPoint(
                x: max((containerSize.width - device.frame.width) / 2, 0),
                y: max((containerSize.height - device.frame.height) / 2, 0)
            )
        }
    }

    private func horizontalSizeClass(for device: Device?) -> SwiftUI.UserInterfaceSizeClass? {
        return sizeClass(for: device?.traits.horizontalSizeClass)
    }

    private func verticalSizeClass(for device: Device?) -> SwiftUI.UserInterfaceSizeClass? {
        return sizeClass(for: device?.traits.verticalSizeClass)
    }

    private func sizeClass(for sizeClass: UIUserInterfaceSizeClass?) -> SwiftUI.UserInterfaceSizeClass? {
        switch sizeClass {
        case .compact:
            return .compact
        case .regular:
            return .regular
        case .unspecified, .none:
            return nil
        @unknown default:
            return nil
        }
    }
}

/// Hosts a catalog item's SwiftUI view, building it exactly once (in `@State`) so
/// its identity, `@State`, and emitted tweak preferences stay stable across
/// playground re-renders — opening the settings sheet re-renders the playground,
/// and rebuilding `item.swiftUIView()` each time would recreate the hosted view
/// and transiently reset its tweak preference to empty (the settings sheet then
/// showed no tweaks). One playground hosts one item, so identity is naturally
/// stable for the playground's lifetime.
private struct PinwheelHostedItem: SwiftUI.View {
    @SwiftUI.State private var view: AnyView

    init(item: PinwheelItem) {
        _view = SwiftUI.State(initialValue: item.swiftUIView())
    }

    var body: some SwiftUI.View {
        view
    }
}

/// The playground's settings: a tweaks-only "Options" screen with a device-icon
/// nav button that pushes the device list. Devices are kept off the Options
/// screen — selecting one resizes the playground and surfaces the device pill.
private struct PinwheelSettingsView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    @SwiftUI.Binding var selectedDeviceIndex: Int?
    var startOnDeviceList: Bool = false

    @Environment(\.dismiss) private var dismiss
    @SwiftUI.State private var showingDevices = false

    var body: some SwiftUI.View {
        NavigationStack {
            optionsList
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showingDevices) {
                    PinwheelDeviceList(selectedIndex: $selectedDeviceIndex)
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        PinLabel("Options").font(.subtitleSemibold)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        SwiftUI.Button("Done") { dismiss() }
                            .tint(PinwheelTheme.Colors.actionText)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        SwiftUI.Button {
                            showingDevices = true
                        } label: {
                            Image(systemName: "iphone.gen3")
                        }
                        .tint(PinwheelTheme.Colors.actionText)
                    }
                }
        }
        .onAppear { if startOnDeviceList { showingDevices = true } }
    }

    @ViewBuilder
    private var optionsList: some SwiftUI.View {
        List {
            ForEach(tweaks) { tweak in
                tweakRow(tweak)
                    .listRowBackground(PinwheelTheme.Colors.primaryBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PinwheelTheme.Colors.primaryBackground)
        .overlay {
            if tweaks.isEmpty {
                PinLabel("No options").color(.secondary)
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
                rowLabels(tweak)
            }
            .buttonStyle(.plain)
        case .toggle(let isOn):
            Toggle(isOn: isOn) { rowLabels(tweak) }
        }
    }

    private func rowLabels(_ tweak: PinwheelTweak) -> some SwiftUI.View {
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

/// The pushed device list. Disabled devices (too big for the screen) are dimmed;
/// the selected one is checked. A trailing Reset (shown only when a non-current
/// device is selected) returns to the real device.
private struct PinwheelDeviceList: SwiftUI.View {
    @SwiftUI.Binding var selectedIndex: Int?

    private let devices = Device.all

    private var showsReset: Bool {
        guard let selectedIndex, let device = devices[safe: selectedIndex] else { return false }
        return !device.isCurrent
    }

    var body: some SwiftUI.View {
        List {
            ForEach(Array(devices.enumerated()), id: \.offset) { index, device in
                SwiftUI.Button {
                    selectedIndex = index
                } label: {
                    HStack {
                        PinLabel(device.title).color(device.isEnabled ? .primary : .tertiary)
                        Spacer()
                        if isSelected(index, device) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(PinwheelTheme.Colors.actionText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!device.isEnabled)
                .listRowBackground(PinwheelTheme.Colors.primaryBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PinwheelTheme.Colors.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                PinLabel("Device").font(.subtitleSemibold)
            }
            if showsReset {
                ToolbarItem(placement: .topBarTrailing) {
                    SwiftUI.Button("Reset") { selectedIndex = nil }
                        .tint(PinwheelTheme.Colors.actionText)
                }
            }
        }
    }

    /// With no explicit selection, the current (real) device is the active one.
    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

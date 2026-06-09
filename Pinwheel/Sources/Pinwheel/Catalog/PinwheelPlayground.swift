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

    @SwiftUI.State private var selectedDeviceIndex: Int?
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
                    selectedDeviceIndex = PinwheelStateStore.selectedDeviceIndex(for: selection)
                    chrome.onClose = onClose
                    chrome.isPresentingItem = true
                }
                .onDisappear {
                    chrome.isPresentingItem = false
                    chrome.showsSettings = false
                    chrome.tweaks = []
                    chrome.onClose = nil
                }
                .sheet(isPresented: $chrome.showsSettings) {
                    PinwheelSettingsView(
                        tweaks: chrome.tweaks,
                        selectedDeviceIndex: selectedDeviceIndex,
                        selection: selection
                    ) { deviceIndex in
                        selectedDeviceIndex = deviceIndex
                        PinwheelStateStore.setSelectedDeviceIndex(deviceIndex, for: selection)
                        chrome.showsSettings = false
                    }
                    .presentationDetents([.medium])
                }
        }
    }

    private var selectedDevice: Device? {
        return selectedDeviceIndex.flatMap { Device.all[safe: $0] }
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

private struct PinwheelSettingsView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    let selectedDeviceIndex: Int?
    let selection: PinwheelSelection
    let selectDevice: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            List {
                if !tweaks.isEmpty {
                    Section("Tweaks") {
                        ForEach(tweaks) { tweak in
                            tweakRow(tweak)
                        }
                    }
                }

                Section("Device") {
                    ForEach(Array(Device.all.enumerated()), id: \.offset) { index, device in
                        SwiftUI.Button {
                            selectDevice(index)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.title)
                                    if device.traits.userInterfaceIdiom == .phone && device.frame.size == UIScreen.main.bounds.size {
                                        Text("Current")
                                            .font(.caption)
                                            .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                                    }
                                }

                                Spacer()

                                if selectedDeviceIndex == index {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SwiftUI.Color(uiColor: .actionText))
                                }
                            }
                        }
                        .disabled(!device.isEnabled)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SwiftUI.Color(uiColor: .primaryBackground))
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SwiftUI.Button("Done") {
                        dismiss()
                    }
                }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(tweak.title)
                    if let description = tweak.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                    }
                }
            }
        case .toggle(let isOn):
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tweak.title)
                    if let description = tweak.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                    }
                }
            }
        }
    }
}

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
                // Letterbox a simulated (smaller) device against the inverse-of-
                // surface token so the resized frame is visible — near-black in
                // light, light in dark — rather than blending into the content.
                .background(
                    chrome.simulatedDevice != nil ? .primaryText : .primaryBackground
                )
                // Animate the frame resize (and letterbox crossfade) when the
                // simulated device changes — including the pill's reset to full size.
                .animation(.easeInOut(duration: 0.25), value: chrome.selectedDeviceIndex)
                // The device pill rides on top of the playground (not in the FAB's
                // overlay window) so its shrink+fade is a plain SwiftUI transition —
                // hosting it in the window collapsed its intrinsic frame on the way
                // out instead of scaling in place.
                .overlay(alignment: .top) {
                    PinwheelDevicePill()
                        .padding(.top, .spacingS)
                }
                .onAppear {
                    // Preview/deep-link renders stay isolated from interactive
                    // catalog persistence: always the host device (no restored
                    // simulation leaking a pill + letterbox into a snapshot), and
                    // no write-back below that would clobber a saved device pick.
                    if !previewMode {
                        chrome.selectedDeviceIndex = PinwheelStateStore.selectedDeviceIndex(for: selection)
                    }
                    chrome.onClose = onClose
                    chrome.isPresentingItem = true
                }
                .onChange(of: chrome.selectedDeviceIndex) { _, newValue in
                    guard !previewMode else { return }
                    PinwheelStateStore.setSelectedDeviceIndex(newValue, for: selection)
                }
                .onDisappear {
                    chrome.isPresentingItem = false
                    chrome.showsSettings = false
                    chrome.selectedDeviceIndex = nil
                    chrome.tweaks = []
                    chrome.onClose = nil
                }
                .sheet(isPresented: $chrome.showsSettings) {
                    PinwheelSettingsView(
                        tweaks: chrome.tweaks,
                        selectedDeviceIndex: $chrome.selectedDeviceIndex
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
            .background(.primaryBackground)
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
        return CGPoint(
            x: max((containerSize.width - device.frame.width) / 2, 0),
            y: max((containerSize.height - device.frame.height) / 2, 0)
        )
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

/// The floating pill showing the simulated device, pinned to the top of the
/// playground and persisting after the settings sheet is dismissed. An indicator —
/// only the reset `×` is interactive. Renders nothing on the real device.
private struct PinwheelDevicePill: SwiftUI.View {
    @Environment(PinwheelChrome.self) private var chrome

    var body: some SwiftUI.View {
        // Shrink toward identity + fade, keyed on the same visibility the FAB uses,
        // so closing dismisses both together and the pill's reset animates away.
        ZStack {
            if chrome.isDevicePillVisible, let device = chrome.simulatedDevice {
                pill(for: device)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.22), value: chrome.isDevicePillVisible)
    }

    private func pill(for device: Device) -> some SwiftUI.View {
        HStack(spacing: .spacingS) {
            // Indicator only — not tappable.
            Image(systemName: "iphone.gen3")
            PinLabel(device.title).font(.caption)

            // The only interactive part: reset to the real device. Clearing the
            // index fades the pill (above) and animates the frame back to full
            // size (the playground animates on `selectedDeviceIndex`).
            SwiftUI.Button {
                chrome.selectedDeviceIndex = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primaryText)
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(
            Capsule()
                .fill(.secondaryBackground)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        )
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

    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            optionsList
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        PinLabel("Options").font(.subtitleSemibold)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            PinwheelDeviceList(selectedIndex: $selectedDeviceIndex)
                        } label: {
                            Image(systemName: "iphone.gen3")
                        }
                        .tint(.actionText)
                    }
                }
        }
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
        .background(.primaryBackground)
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
/// the selected one is checked. Resetting to the real device is via the pill's `×`.
private struct PinwheelDeviceList: SwiftUI.View {
    @SwiftUI.Binding var selectedIndex: Int?

    private let devices = Device.all

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
                                .foregroundStyle(.actionText)
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
        .background(.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                PinLabel("Device").font(.subtitleSemibold)
            }
        }
    }

    /// With no explicit selection, the current (real) device is the active one.
    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

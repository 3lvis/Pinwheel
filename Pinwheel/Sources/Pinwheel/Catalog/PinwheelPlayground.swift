import SwiftUI

struct PinwheelPlayground: SwiftUI.View {
    let item: PinwheelItem
    let selection: PinwheelSelection
    let onClose: () -> Void

    var previewMode: Bool = false
    var autoApplyTweak: String?

    @SwiftUI.State private var didApplyPreviewTweak = false
    @SwiftUI.State private var didDumpPreviewTweaks = false

    @Environment(PinwheelChrome.self) private var chrome

    var body: some SwiftUI.View {
        @Bindable var chrome = chrome
        return content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Letterbox a simulated device against the inverse-of-surface token
            // so the resized frame stays visible in light and dark.
            .background(
                chrome.simulatedDevice != nil ? .primaryText : .primaryBackground
            )
            // Don't animate the device-frame resize with `.animation(value:)`: it
            // recurses SwiftUI's layout into a stack overflow (crashes on every
            // device pick). The pill rides the playground, not the FAB window, so
            // its transition scales in place instead of collapsing.
            .overlay(alignment: .top) {
                PinwheelDevicePill()
                    .padding(.top, .spacingS)
            }
            .onAppear {
                // Preview renders skip device restore/persistence so a saved
                // simulation can't leak into a snapshot or clobber a real pick.
                if !previewMode {
                    chrome.selectedDeviceIndex = PinwheelStateStore.selectedDeviceIndex(for: selection)
                }
                chrome.onClose = onClose
                chrome.isPresentingItem = true
                chrome.componentName = item.title
                chrome.componentID = selection.itemID
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
                chrome.componentName = nil
                chrome.componentID = nil
            }
            .sheet(isPresented: $chrome.showsSettings) {
                PinwheelSettingsView(
                    tweaks: chrome.tweaks,
                    selectedDeviceIndex: $chrome.selectedDeviceIndex
                )
                .presentationDetents([.medium, .large])
            }
    }

    private var selectedDevice: Device? {
        return chrome.selectedDeviceIndex.flatMap { Device.all[safe: $0] }
    }

    private var content: some SwiftUI.View {
        let device = selectedDevice
        return PinwheelHostedItem(item: item)
            .environment(\.horizontalSizeClass, horizontalSizeClass(for: device))
            .environment(\.verticalSizeClass, verticalSizeClass(for: device))
            .background(.primaryBackground)
            .frame(width: device?.frame.width, height: device?.frame.height)
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
            writePreviewTweakTitles(tweaks.map(\.title))
        }

        guard let target = autoApplyTweak, !didApplyPreviewTweak,
              let tweak = tweaks.first(where: { $0.title == target }) else {
            return
        }
        didApplyPreviewTweak = true
        // Defer past the current view update — mutating state mid-update is undefined.
        DispatchQueue.main.async {
            tweak.applyAsPreviewVariant()
        }
    }

    // Writes tweak titles (one per line) to Documents/pinwheel-preview-tweaks.txt;
    // `Scripts/sweep.sh --preview` reads that file to enumerate a component's variants.
    private func writePreviewTweakTitles(_ titles: [String]) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let url = directory.appendingPathComponent("pinwheel-preview-tweaks.txt")
        try? titles.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
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

// The component's name and capture version, shown as a pill on top of the playground so it reads the
// same number the Figma plugin lists. When a device is simulated it also shows that, with a reset.
private struct PinwheelDevicePill: SwiftUI.View {
    @Environment(PinwheelChrome.self) private var chrome

    var body: some SwiftUI.View {
        ZStack {
            if chrome.isPresentingItem, let name = chrome.componentName {
                pill(name: name)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.22), value: chrome.isPresentingItem)
    }

    private func pill(name: String) -> some SwiftUI.View {
        HStack(spacing: .spacingS) {
            PinLabel(name).font(.caption)
            if let id = chrome.componentID, let version = PinCaptureVersions.shared.version(for: id) {
                PinLabel("v\(version)").font(.caption).color(.secondary)
            }
            if chrome.isDevicePillVisible, let device = chrome.simulatedDevice {
                Image(systemName: "iphone.gen3")
                PinLabel(device.title).font(.caption)
                SwiftUI.Button {
                    chrome.selectedDeviceIndex = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondaryText)
                }
                .buttonStyle(.plain)
            }
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

// Builds the item's view once (in `@State`) so playground re-renders don't
// recreate it and reset its emitted tweak preference to empty.
private struct PinwheelHostedItem: SwiftUI.View {
    private let id: String
    @SwiftUI.State private var view: AnyView
    @Environment(\.pinCaptureSink) private var captureSink

    init(item: PinwheelItem) {
        id = item.id
        _view = SwiftUI.State(initialValue: item.swiftUIView())
    }

    var body: some SwiftUI.View {
        if let captureSink {
            // Capture-on-view: whatever component the catalog shows is captured and handed to the
            // sink (a consumer pushes it), so there's no button/script — just viewing refreshes it.
            view
                .environment(\.pinCapturing, true)
                .backgroundPreferenceValue(PinCaptureKey.self) { captured in
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { captureSink(id, captured, proxy) }
                            .onChange(of: captured.count) { captureSink(id, captured, proxy) }
                    }
                }
        } else {
            view
        }
    }
}

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
                    .listRowBackground(Color.primaryBackground)
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
                .listRowBackground(Color.primaryBackground)
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

    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

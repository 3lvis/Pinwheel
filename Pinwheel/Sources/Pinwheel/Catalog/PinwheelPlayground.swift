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
            // The pill rides the playground rather than the FAB window, so its transition scales in
            // place instead of collapsing.
            .overlay(alignment: .top) {
                PinwheelDevicePill(previewMode: previewMode)
                    .padding(.top, .spacing2)
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
                chrome.componentVariant = autoApplyTweak
            }
            .onChange(of: chrome.selectedDeviceIndex) { _, newValue in
                guard !previewMode else { return }
                PinwheelStateStore.setSelectedDeviceIndex(newValue, for: selection)
            }
            .onDisappear {
                chrome.isPresentingItem = false
                chrome.showsTweaks = false
                chrome.selectedDeviceIndex = nil
                chrome.tweaks = []
                chrome.onClose = nil
                chrome.componentName = nil
                chrome.componentID = nil
                chrome.componentVariant = nil
            }
            .pinwheelTray(path: $chrome.tweakPath) { destination in
                switch destination {
                case .tweaks:
                    PinwheelTweaksView(
                        tweaks: chrome.tweaks,
                        openDevices: { chrome.tweakPath.append(.device) },
                        close: { chrome.tweakPath.removeAll() }
                    ).tray

                case .device:
                    PinwheelDeviceList(
                        selectedIndex: $chrome.selectedDeviceIndex,
                        close: { chrome.tweakPath.removeAll() }
                    ).tray
                }
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
            writePreviewTweakTitles(tweaks.flatMap(\.previewVariantTitles))
        }

        guard let target = autoApplyTweak, !didApplyPreviewTweak,
              let tweak = tweaks.first(where: { $0.previewVariantTitles.contains(target) }) else {
            return
        }
        didApplyPreviewTweak = true
        // Defer past the current view update — mutating state mid-update is undefined.
        DispatchQueue.main.async {
            tweak.applyAsPreviewVariant(named: target)
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

private struct PinwheelDevicePill: SwiftUI.View {
    let previewMode: Bool
    @Environment(PinwheelChrome.self) private var chrome
    @SwiftUI.State private var versionFaded = false
    @SwiftUI.State private var showingBuild = false

    private var isVisible: Bool {
        guard chrome.isPresentingItem, chrome.componentName != nil else { return false }
        if previewMode || chrome.simulatedDevice != nil { return true }
        return !versionFaded
    }

    var body: some SwiftUI.View {
        ZStack {
            if isVisible, let name = chrome.componentName {
                pill(name: name)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        showingBuild = true
                        versionFaded = false
                    }
                    .task(id: showingBuild) {
                        guard showingBuild else { return }
                        try? await Task.sleep(for: .seconds(4))
                        showingBuild = false
                    }
                    // The playground is constructed a beat before it's presented, so time the fade from
                    // the pill appearing, not from construction (which spends the window unseen).
                    .task {
                        try? await Task.sleep(for: .seconds(4))
                        versionFaded = true
                    }
            }
        }
        .animation(.easeOut(duration: 0.35), value: isVisible)
        .onChange(of: chrome.componentID) { versionFaded = false }
    }

    private func pill(name: String) -> some SwiftUI.View {
        HStack(spacing: .spacing2) {
            PinLabel(showingBuild ? PinwheelBuild.label : name).font(.caption)
            if let variant = chrome.componentVariant {
                PinLabel("· \(variant)").font(.caption).color(.secondary)
            }
            if let id = chrome.componentID, let version = PinCaptureVersions.shared.version(for: id) {
                PinLabel("v\(version)").font(.caption).color(.secondary)
            }
            if chrome.isDevicePillVisible, let device = chrome.simulatedDevice {
                Image(systemName: "iphone.gen3")
                    .font(PinTextStyle.body.font(in: chrome.theme))
                    .symbolRenderingMode(.monochrome)
                    .imageScale(.large)
                PinLabel(device.title).font(.caption)
                SwiftUI.Button {
                    chrome.selectedDeviceIndex = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(PinTextStyle.body.font(in: chrome.theme))
                        .symbolRenderingMode(.monochrome)
                        .imageScale(.large)
                        .foregroundStyle(.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.primaryText)
        .padding(.horizontal, .spacing3)
        .padding(.vertical, .spacing2)
        .background(
            Capsule()
                .fill(.secondaryBackground)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        )
    }
}

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
            view.onAppear { captureSink(id) }
        } else {
            view
        }
    }
}

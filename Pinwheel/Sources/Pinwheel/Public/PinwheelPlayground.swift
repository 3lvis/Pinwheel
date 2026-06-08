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
    @SwiftUI.State private var tweaks: [PinwheelTweak] = []
    @SwiftUI.State private var showsSettings = false
    @SwiftUI.State private var didApplyPreviewTweak = false
    @SwiftUI.State private var didDumpPreviewTweaks = false

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            ZStack {
                content(in: geometry)

                PinwheelFloatingControls(tweakCount: tweaks.count) {
                    showsSettings = true
                } close: {
                    onClose()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SwiftUI.Color(uiColor: .primaryBackground).ignoresSafeArea())
            .onAppear {
                selectedDeviceIndex = PinwheelStateStore.selectedDeviceIndex(for: selection)
            }
            .sheet(isPresented: $showsSettings) {
                PinwheelSettingsView(
                    tweaks: tweaks,
                    selectedDeviceIndex: selectedDeviceIndex,
                    selection: selection
                ) { deviceIndex in
                    selectedDeviceIndex = deviceIndex
                    PinwheelStateStore.setSelectedDeviceIndex(deviceIndex, for: selection)
                    showsSettings = false
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

        return item.swiftUIView()
            .environment(\.horizontalSizeClass, horizontalSizeClass(for: device))
            .environment(\.verticalSizeClass, verticalSizeClass(for: device))
            .background(SwiftUI.Color(uiColor: .primaryBackground))
            .frame(width: size.width, height: size.height, alignment: .center)
            .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
            .clipped()
            .onPreferenceChange(PinwheelTweaksPreferenceKey.self) { tweaks in
                self.tweaks = tweaks
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

private struct PinwheelFloatingControls: SwiftUI.View {
    let tweakCount: Int
    let settings: () -> Void
    let close: () -> Void

    @SwiftUI.State private var cornerIndex = State.lastCornerForTweakingButton ?? 3
    @GestureState private var dragOffset: CGSize = .zero

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            VStack(spacing: .spacingS) {
                PinwheelFloatingButton(symbol: "wrench.adjustable.fill", badge: tweakCount, action: settings)
                    .accessibilityIdentifier("pinwheel.settings")
                PinwheelFloatingButton(symbol: "xmark", badge: 0, action: close)
                    .accessibilityIdentifier("pinwheel.close")
            }
            .position(position(in: geometry.size))
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let current = CGPoint(
                            x: position(in: geometry.size).x + value.translation.width,
                            y: position(in: geometry.size).y + value.translation.height
                        )
                        cornerIndex = nearestCorner(to: current, in: geometry.size)
                        State.lastCornerForTweakingButton = cornerIndex
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: cornerIndex)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func position(in size: CGSize) -> CGPoint {
        return position(for: cornerIndex, in: size)
    }

    private func position(for index: Int, in size: CGSize) -> CGPoint {
        let margin = CGFloat.spacingL + CGFloat.spacingXXL
        let stackHeight = CGFloat.spacingXXL * 4 + CGFloat.spacingS
        let top = margin + stackHeight / 2
        let bottom = size.height - margin - stackHeight / 2
        let left = margin
        let right = size.width - margin

        switch index {
        case 0:
            return CGPoint(x: left, y: top)
        case 1:
            return CGPoint(x: right, y: top)
        case 2:
            return CGPoint(x: left, y: bottom)
        default:
            return CGPoint(x: right, y: bottom)
        }
    }

    private func nearestCorner(to point: CGPoint, in size: CGSize) -> Int {
        let positions = (0...3).map { position(for: $0, in: size) }

        return positions.enumerated().min { first, second in
            point.distance(to: first.element) < point.distance(to: second.element)
        }?.offset ?? 3
    }
}

private struct PinwheelFloatingButton: SwiftUI.View {
    let symbol: String
    let badge: Int
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(SwiftUI.Color(uiColor: .primaryBackground))
                    .frame(width: .spacingXXL * 2, height: .spacingXXL * 2)
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(SwiftUI.Color(uiColor: .actionText))
                    }

                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SwiftUI.Color(uiColor: .primaryBackground))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SwiftUI.Color(uiColor: .actionText)))
                        .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
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

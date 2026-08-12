import SwiftUI

struct PinwheelTweaksView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    @SwiftUI.Binding var selectedDeviceIndex: Int?

    @Environment(\.pinwheelTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            PinwheelSheet(title: "Tweaks") {
                if tweaks.isEmpty {
                    PinLabel("No tweaks")
                        .color(.secondary)
                        .frame(maxWidth: .infinity, minHeight: .minimumControlHeight * 2)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(tweaks) { tweak in
                            tweakRow(tweak)
                        }
                    }
                }
            } trailing: {
                NavigationLink {
                    PinwheelDeviceList(selectedIndex: $selectedDeviceIndex)
                } label: {
                    Image(systemName: "iphone.gen3")
                        .font(PinTextStyle.subtitleSemibold.font(in: theme))
                }
                .accessibilityLabel("Device")
                .accessibilityIdentifier("pinwheel.device")
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
                    .padding(.horizontal, .spacingXL)
                    .padding(.vertical, .spacingM)
                    .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .toggle(let isOn):
            Toggle(isOn: isOn) { tweakLabels(tweak) }
                .tint(.actionText)
                .padding(.horizontal, .spacingXL)
                .padding(.vertical, .spacingM)
                .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
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
    }
}

struct PinwheelDeviceList: SwiftUI.View {
    @SwiftUI.Binding var selectedIndex: Int?

    private let devices = Device.all

    var body: some SwiftUI.View {
        PinwheelSheet(title: "Device", leading: .back, showsDone: true) {
            ForEach(Array(devices.enumerated()), id: \.offset) { index, device in
                PickerRow(title: device.title, isSelected: isSelected(index, device)) {
                    selectedIndex = index
                }
                .disabled(!device.isEnabled)
            }
        }
    }

    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

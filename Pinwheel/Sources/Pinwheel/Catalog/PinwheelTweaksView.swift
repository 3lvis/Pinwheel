import SwiftUI

struct PinwheelTweaksView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    @SwiftUI.Binding var selectedDeviceIndex: Int?

    @Environment(\.pinwheelTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            PinwheelSheet(model: PinwheelSheetModel(title: "Tweaks")) {
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
                        .font(PinTextStyle.body.font(in: theme))
                        .symbolRenderingMode(.monochrome)
                        .imageScale(.large)
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
                    .padding(.horizontal, .spacing6)
                    .padding(.vertical, .spacing3)
                    .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .toggle(let isOn):
            Toggle(isOn: isOn) { tweakLabels(tweak) }
                .tint(.actionText)
                .padding(.horizontal, .spacing6)
                .padding(.vertical, .spacing3)
                .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
        case .select(let options, let selection):
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                PickerRow(title: option, isSelected: index == tweak.selectedOption) {
                    selection.wrappedValue = index
                    dismiss()
                }
                .padding(.horizontal, .spacing3)
            }
        }
    }

    private func tweakLabels(_ tweak: PinwheelTweak) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacing1) {
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

    @Environment(\.dismiss) private var dismiss

    private let devices = Device.all

    var body: some SwiftUI.View {
        PinwheelSheet(PinwheelSheetModel(title: "Device", leading: .back)) {
            ForEach(Array(devices.enumerated()), id: \.offset) { index, device in
                PickerRow(title: device.title, isSelected: isSelected(index, device)) {
                    selectedIndex = index
                    dismiss()
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

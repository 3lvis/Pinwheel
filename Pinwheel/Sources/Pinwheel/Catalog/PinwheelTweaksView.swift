import SwiftUI

struct PinwheelTweaksView: SwiftUI.View {
    let tweaks: [PinwheelTweak]
    let openDevices: () -> Void
    let close: () -> Void

    @Environment(\.pinwheelTheme) private var theme

    var tray: PinTray {
        PinTray("Tweaks") {
            if tweaks.isEmpty {
                PinLabel("No tweaks")
                    .color(.secondary)
                    .frame(maxWidth: .infinity, minHeight: .minimumControlHeight * 2)
            } else {
                PinTraySection {
                    ForEach(tweaks) { tweak in
                        tweakRow(tweak)
                    }
                }
            }
        }
        .titleAccessory {
            SwiftUI.Button(action: openDevices) {
                Image(systemName: "iphone.gen3")
                    .font(PinTextStyle.body.font(in: theme))
                    .symbolRenderingMode(.monochrome)
                    .imageScale(.large)
                    .foregroundStyle(.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Device")
            .accessibilityIdentifier("pinwheel.device")
        }
    }

    var body: some SwiftUI.View { EmptyView() }

    @ViewBuilder
    private func tweakRow(_ tweak: PinwheelTweak) -> some SwiftUI.View {
        switch tweak.control {
        case .action(let action):
            SwiftUI.Button {
                action()
                close()
            } label: {
                tweakLabels(tweak)
                    .padding(.horizontal, .spacing3)
                    .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .toggle(let isOn):
            Toggle(isOn: isOn) { tweakLabels(tweak) }
                .tint(.actionText)
                .padding(.horizontal, .spacing3)
                .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
        case .select(let options, let selection):
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                PinTrayChoice(option, isChosen: index == tweak.selectedOption) {
                    selection.wrappedValue = index
                    close()
                }
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

struct PinwheelDeviceList {
    @SwiftUI.Binding var selectedIndex: Int?
    let close: () -> Void

    private let devicesThatFit = Device.all.enumerated().filter { $0.element.fitsThisScreen }

    init(selectedIndex: SwiftUI.Binding<Int?>, close: @escaping () -> Void) {
        _selectedIndex = selectedIndex
        self.close = close
    }

    var tray: PinTray {
        PinTray("Device") {
            PinTraySection {
                ForEach(devicesThatFit, id: \.offset) { index, device in
                    PinTrayChoice(device.title, isChosen: isSelected(index, device)) {
                        selectedIndex = index
                        close()
                    }
                }
            }
        }
    }

    private func isSelected(_ index: Int, _ device: Device) -> Bool {
        if let selectedIndex { return selectedIndex == index }
        return device.isCurrent
    }
}

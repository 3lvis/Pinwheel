import SwiftUI
import Pinwheel

struct AppleControlsGallery: SwiftUI.View {
    @SwiftUI.State private var on = true
    @SwiftUI.State private var mode = 0
    @SwiftUI.State private var amount = 0.6
    @SwiftUI.State private var count = 2
    @SwiftUI.State private var date = Date(timeIntervalSince1970: 1_700_000_000)

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            PinLabel("Apple controls").font(.title)
            PinLabel("Each control captures as a named placeholder, ready to swap for its Apple Figma iOS UI Kit component.")
                .font(.footnote)
                .color(.secondary)

            control("Toggle") { Toggle("", isOn: $on).labelsHidden() }
            control("Segmented") {
                Picker("", selection: $mode) {
                    Text("Day").tag(0)
                    Text("Week").tag(1)
                    Text("Month").tag(2)
                }
                .pickerStyle(.segmented)
            }
            control("Slider") { Slider(value: $amount) }
            control("Stepper") { Stepper("", value: $count, in: 0...9).labelsHidden() }
            control("Progress") { ProgressView(value: amount).tint(.actionText) }
            control("DatePicker") { DatePicker("", selection: $date, displayedComponents: .date).labelsHidden() }
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.primaryBackground)
    }

    private func control(_ name: String, @ViewBuilder _ content: () -> some SwiftUI.View) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            PinLabel(name).font(.caption).color(.secondary)
            content().pinCapturedRasterized(name: name)
        }
    }
}

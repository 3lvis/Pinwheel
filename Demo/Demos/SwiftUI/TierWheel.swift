import Pinwheel
import SwiftUI
import UIKit

/// A tier and what it costs. The wheel's row.
struct Tier: Hashable {
    let reach: String
    let price: String
}

/// The tier wheel: UIKit's `UIPickerView`, bridged, rather than SwiftUI's `Picker`.
///
/// SwiftUI's wheel cannot be told to travel. Setting its selection inside `withAnimation` snaps — measured
/// at forty frames a hundred milliseconds apart, holding four states with nothing in flight between any of
/// them. `selectRow(_:inComponent:animated:)` is the travel, and only the UIKit control has it, which is
/// the whole reason this is bridged and not declared.
struct TierWheel: UIViewRepresentable {
    let tiers: [Tier]
    @Binding var selection: Int
    /// Whether a change of selection travels there or arrives there. A finger is already travelling; a
    /// tutorial driving the wheel from outside is what needs the animation.
    var travels = false

    func makeUIView(context: Context) -> UIPickerView {
        let wheel = UIPickerView()
        wheel.dataSource = context.coordinator
        wheel.delegate = context.coordinator
        wheel.selectRow(selection, inComponent: 0, animated: false)
        return wheel
    }

    func updateUIView(_ wheel: UIPickerView, context: Context) {
        context.coordinator.wheel = self
        guard wheel.selectedRow(inComponent: 0) != selection else { return }
        wheel.selectRow(selection, inComponent: 0, animated: travels)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var wheel: TierWheel

        init(_ wheel: TierWheel) { self.wheel = wheel }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            wheel.tiers.count
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            wheel.selection = row
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let tier = wheel.tiers[row]

            let reach = UILabel()
            reach.text = tier.reach
            reach.font = .body
            reach.textColor = .primaryText

            let price = UILabel()
            price.text = tier.price
            price.font = .titleSemibold
            price.textColor = .primaryText
            price.setContentCompressionResistancePriority(.required, for: .horizontal)
            price.setContentHuggingPriority(.required, for: .horizontal)

            let content = UIStackView(arrangedSubviews: [reach, price])
            content.alignment = .center
            content.isLayoutMarginsRelativeArrangement = true
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0, leading: .spacing4, bottom: 0, trailing: .spacing4
            )
            return content
        }
    }
}

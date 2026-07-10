import UIKit
import Pinwheel

struct ColorItem {
    let color: UIColor
    let title: String
}

class UIPinColorDemo: UIPinView {
    private let items: [ColorItem] = [
        ColorItem(color: .primaryText, title: "Primary Text"),
        ColorItem(color: .secondaryText, title: "Secondary Text"),
        ColorItem(color: .tertiaryText, title: "Tertiary Text"),
        ColorItem(color: .actionText, title: "Action Text"),
        ColorItem(color: .criticalText, title: "Critical Text"),
        ColorItem(color: .primaryBackground, title: "Primary Background"),
        ColorItem(color: .secondaryBackground, title: "Secondary Background"),
        ColorItem(color: .actionBackground, title: "Action Background"),
        ColorItem(color: .criticalBackground, title: "Critical Background")
    ]

    // A VStack of colored rows (not a UITableView): eager and fully in the view tree, so every row
    // captures as auto-layout — the UIKit counterpart of the SwiftUI Color demo. The table demos
    // (uikit-tableview, dataSource-tableview) cover the UITableView capture path.
    override func setup() {
        let stack = UIStackView(withAutoLayout: true)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        items.forEach { stack.addArrangedSubview(row($0)) }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // The title in black and white, so it stays readable whatever the bar's color.
    private func row(_ item: ColorItem) -> UIView {
        let row = UIStackView(arrangedSubviews: [label(item.title, color: .black), label(item.title, color: .white)])
        row.axis = .horizontal
        row.spacing = .spacingS
        row.backgroundColor = item.color
        row.isLayoutMarginsRelativeArrangement = true
        row.insetsLayoutMarginsFromSafeArea = false
        row.layoutMargins = UIEdgeInsets(top: .spacingM, left: .spacingL, bottom: .spacingM, right: .spacingL)
        return row
    }

    private func label(_ text: String, color: UIColor) -> UILabel {
        let label = UIPinLabel(font: .body)
        label.text = text
        label.textColor = color
        return label
    }
}

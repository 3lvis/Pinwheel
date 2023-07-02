import UIKit
import Pinwheel

class PinSpacing: View {
    func makeLabel(text: String) -> Label {
        let label = Label(style: .body)
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .tertiaryText
        label.textColor = .primaryText
        label.textAlignment = .center
        return label
    }

    override func setup() {
        let spacingXSView = makeLabel(text: "👈      spacingXS \(CGFloat.spacingXS)    👉")
        addSubview(spacingXSView)

        let spacingSView = makeLabel(text: "👈        spacingS \(CGFloat.spacingS)    👉")
        addSubview(spacingSView)

        let spacingMView = makeLabel(text: "👈        spacingM \(CGFloat.spacingM)    👉")
        addSubview(spacingMView)

        let spacingLView = makeLabel(text: "👈        spacingL \(CGFloat.spacingL)    👉")
        addSubview(spacingLView)

        let spacingXLView = makeLabel(text: "👈        spacingXL \(CGFloat.spacingXL)    👉")
        addSubview(spacingXLView)

        NSLayoutConstraint.activate([
            spacingXSView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingXL),
            spacingXSView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXS),
            spacingXSView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXS),

            spacingSView.topAnchor.constraint(equalTo: spacingXSView.bottomAnchor, constant: .spacingXL),
            spacingSView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingS),
            spacingSView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingS),

            spacingMView.topAnchor.constraint(equalTo: spacingSView.bottomAnchor, constant: .spacingXL),
            spacingMView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            spacingMView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),

            spacingLView.topAnchor.constraint(equalTo: spacingMView.bottomAnchor, constant: .spacingXL),
            spacingLView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            spacingLView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            spacingXLView.topAnchor.constraint(equalTo: spacingLView.bottomAnchor, constant: .spacingXL),
            spacingXLView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXL),
            spacingXLView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXL)
        ])
    }
}
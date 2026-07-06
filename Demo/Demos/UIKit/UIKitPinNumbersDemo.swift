import UIKit
import Pinwheel

class UIKitPinNumbersDemo: UIKitPinView {
    func makeLabel(text: String) -> UIKitPinLabel {
        let label = UIKitPinLabel(font: .body)
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .tertiaryText
        label.textColor = .primaryText
        label.textAlignment = .center
        return label
    }

    override func setup() {
        let spacingXXSView = makeLabel(text: "👈      spacingXXS \(CGFloat.spacingXXS)    👉")
        addSubview(spacingXXSView)

        let spacingXSView = makeLabel(text: "👈      spacingXS \(CGFloat.spacingXS)    👉")
        addSubview(spacingXSView)

        let spacingXMView = makeLabel(text: "👈      spacingXM \(CGFloat.spacingXM)    👉")
        addSubview(spacingXMView)

        let spacingSView = makeLabel(text: "👈        spacingS \(CGFloat.spacingS)    👉")
        addSubview(spacingSView)

        let spacingMView = makeLabel(text: "👈        spacingM \(CGFloat.spacingM)    👉")
        addSubview(spacingMView)

        let spacingLView = makeLabel(text: "👈        spacingL \(CGFloat.spacingL)    👉")
        addSubview(spacingLView)

        let spacingXLView = makeLabel(text: "👈        spacingXL \(CGFloat.spacingXL)    👉")
        addSubview(spacingXLView)

        let spacingXXLView = makeLabel(text: "👈        spacingXXL \(CGFloat.spacingXXL)    👉")
        addSubview(spacingXXLView)

        let radiusMView = makeLabel(text: "radiusM \(CGFloat.radiusM)")
        radiusMView.layer.cornerRadius = .radiusM
        radiusMView.layer.masksToBounds = true
        addSubview(radiusMView)

        NSLayoutConstraint.activate([
            spacingXXSView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingXXL),
            spacingXXSView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXXS),
            spacingXXSView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXXS),

            spacingXSView.topAnchor.constraint(equalTo: spacingXXSView.bottomAnchor, constant: .spacingXXL),
            spacingXSView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXS),
            spacingXSView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXS),

            spacingXMView.topAnchor.constraint(equalTo: spacingXSView.bottomAnchor, constant: .spacingXXL),
            spacingXMView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXM),
            spacingXMView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXM),

            spacingSView.topAnchor.constraint(equalTo: spacingXMView.bottomAnchor, constant: .spacingXXL),
            spacingSView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingS),
            spacingSView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingS),

            spacingMView.topAnchor.constraint(equalTo: spacingSView.bottomAnchor, constant: .spacingXXL),
            spacingMView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            spacingMView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),

            spacingLView.topAnchor.constraint(equalTo: spacingMView.bottomAnchor, constant: .spacingXXL),
            spacingLView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            spacingLView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL),

            spacingXLView.topAnchor.constraint(equalTo: spacingLView.bottomAnchor, constant: .spacingXXL),
            spacingXLView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXL),
            spacingXLView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXL),

            spacingXXLView.topAnchor.constraint(equalTo: spacingXLView.bottomAnchor, constant: .spacingXXL),
            spacingXXLView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXXL),
            spacingXXLView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXXL),

            radiusMView.topAnchor.constraint(equalTo: spacingXXLView.bottomAnchor, constant: .spacingXXL),
            radiusMView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            radiusMView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL)
        ])
    }
}

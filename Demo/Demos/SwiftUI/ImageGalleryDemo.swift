import SwiftUI
import Pinwheel

struct ImageGalleryDemo: SwiftUI.View {
    private struct Photo: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let image: UIImage
        let fileURL: URL
    }

    private let photos: [Photo]

    init() {
        let specs = [
            ("Sunset Ridge", "Landscape", UIColor.systemOrange, UIColor.systemPink),
            ("Ocean Deep", "Seascape", UIColor.systemTeal, UIColor.systemBlue),
            ("Forest Trail", "Woodland", UIColor.systemGreen, UIColor.systemMint)
        ]
        photos = specs.enumerated().map { index, spec in
            let image = Self.swatch(spec.2, spec.3)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("gallery-\(index).png")
            try? image.pngData()?.write(to: url)
            return Photo(title: spec.0, subtitle: spec.1, image: image, fileURL: url)
        }
    }

    private static func swatch(_ top: UIColor, _ bottom: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120)).image { context in
            top.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120, height: 60))
            bottom.setFill(); context.fill(CGRect(x: 0, y: 60, width: 120, height: 60))
        }
    }

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingM) {
                ForEach(photos) { photo in
                    HStack(spacing: .spacingM) {
                        AsyncImage(url: photo.fileURL) { image in
                            image.resizable()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: .radiusM).fill(.secondaryBackground)
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: .radiusM))
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            PinLabel(photo.title).font(.bodySemibold)
                            PinLabel(photo.subtitle).font(.caption).color(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.spacingM)
                    .background(.secondaryBackground)
                    .cornerRadius(.radiusM)
                }
            }
            .padding(.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.primaryBackground)
    }
}

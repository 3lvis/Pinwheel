import SwiftUI
import Pinwheel

struct PinTrayDemo: View {
    private enum Destination: Hashable {
        case boost
        case howItWorks
        case payWith
        case region
    }

    private let tiers = [
        Tier(reach: "692 – 1.1K impressions", price: "$1"),
        Tier(reach: "6.4K – 12K impressions", price: "$10"),
        Tier(reach: "15K – 30K impressions", price: "$25"),
        Tier(reach: "30K – 60K impressions", price: "$50"),
        Tier(reach: "60K – 119K impressions", price: "$100"),
    ]

    private let methods = [
        (name: "Pay with Apple", icon: "apple.logo"),
        (name: "Pay with X Money", icon: "dollarsign.circle"),
    ]

    @State private var path: [Destination] = []
    @State private var tier = 2
    @State private var tutorialStep = 0
    @State private var method = 0
    @State private var region = "United Kingdom"
    @State private var query = ""

    var body: some View {
        VStack(spacing: .spacing4) {
            PinLabel("A tray sequence, each one as tall as its own content.")
                .color(.secondary)
                .multilineTextAlignment(.center)
            PinButton("Show Tray") { path = [.boost] }
        }
        .padding(.spacing6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pinwheelTray(path: $path) { destination in
            switch destination {
            case .boost: boost
            case .howItWorks: howItWorks
            case .payWith: payWith
            case .region: regions
            }
        }
    }

    private var boost: PinTray {
        PinTray("Boost Post") {
            PinTrayLink("Get up to 3x more likes.", phrase: "Learn more") {}
            reach(selection: $tier)
            PinTraySection {
                PinTrayValue("Region", value: region) { path.append(.region) }
                PinTrayValue("Pay with", value: methods[method].name) { path.append(.payWith) }
            }
            PinTrayLink(
                "By clicking the Boost Post button below, you agree to our",
                phrase: "Terms and Conditions"
            ) {}
            .font(.footnote)
        }
        .titleAccessory {
            SwiftUI.Button { path.append(.howItWorks) } label: {
                Image(systemName: "questionmark.circle")
            }
            .accessibilityLabel("How it works")
        }
        .commit("Boost Post") { path.removeAll() }
    }

    private var tutorialTier: Int {
        let last = tiers.count - 1
        let phase = tutorialStep % (last * 2)
        return phase <= last ? phase : last * 2 - phase
    }

    private let wheelSelectionBandInset = CGFloat.spacing2

    private func reach(selection: Binding<Int>, travels: Bool = false) -> some View {
        TierWheel(tiers: tiers, selection: selection, travels: travels)
            .frame(height: 156)
        .padding(.horizontal, -wheelSelectionBandInset)
    }

    private var howItWorks: PinTray {
        PinTray("How it works") {
            reach(selection: .constant(tutorialTier), travels: true)
                .allowsHitTesting(false)
            PinTrayText(
                "Select your boost tier and watch your post go viral. Boosted posts are labelled as boosted."
            )
            .centred()
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.1))
                    withAnimation { tutorialStep += 1 }
                }
            }
        }
        .commit("Got It") { path.removeLast() }
    }

    private var payWith: PinTray {
        PinTray("Pay with") {
            PinTraySection {
                ForEach(Array(methods.enumerated()), id: \.offset) { index, way in
                    PinTrayChoice(way.name, systemImage: way.icon, isChosen: index == method) {
                        method = index
                        path.removeLast()
                    }
                }
            }
        }
    }

    private var regions: PinTray {
        PinTray("Region") {
            PinTraySection {
                if matches.isEmpty {
                    PinTrayText("No regions match “\(query)”").centred()
                } else {
                    ForEach(matches, id: \.self) { name in
                        PinTrayChoice(name, isChosen: name == region) {
                            region = name
                            path.removeLast()
                        }
                        .accessibilityIdentifier("pinwheel.tray.country.\(name)")
                    }
                }
            }
        }
        .detent(.filling)
        .floating { PinTraySearchField("Search Country, City, or Region", text: $query) }
    }

    private var matches: [String] {
        guard !query.isEmpty else { return Self.countries }
        let needle = query.lowercased()
        return Self.countries
            .filter { $0.lowercased().contains(needle) }
            .sorted { first, second in
                let firstStarts = first.lowercased().hasPrefix(needle)
                let secondStarts = second.lowercased().hasPrefix(needle)
                return firstStarts == secondStarts ? first < second : firstStarts
            }
    }

    private static let countries: [String] = Locale.Region.isoRegions
        .filter { $0.subRegions.isEmpty }
        .compactMap { Locale.current.localizedString(forRegionCode: $0.identifier) }
        .sorted()
}

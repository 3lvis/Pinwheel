import SwiftUI

struct PinwheelCatalogView: SwiftUI.View {
    let sections: [PinwheelSection]
    let usesEmbeddedNavigation: Bool
    let themes: [PinwheelTheme]

    @State private var selectedSectionID: String?
    @State private var fullscreenItem: PresentedPinwheelItem?
    @State private var sheetItem: PresentedPinwheelItem?
    @State private var displayPath: [DisplayAxis] = []

    enum DisplayAxis: Hashable {
        case section
        case theme
        case appearance
    }
    @State private var restoredSelection = false
    @State private var chrome = PinwheelChrome()

    init(sections: [PinwheelSection], usesEmbeddedNavigation: Bool, themes: [PinwheelTheme]) {
        self.sections = sections
        self.usesEmbeddedNavigation = usesEmbeddedNavigation
        self.themes = themes
        self._selectedSectionID = State(initialValue: PinwheelStateStore.selectedSectionID)
    }

    var body: some SwiftUI.View {
        Group {
            if usesEmbeddedNavigation {
                NavigationStack {
                    content
                }
            } else {
                content
            }
        }
        .environment(chrome)
        .environment(\.pinwheelTheme, chrome.theme)
        .preferredColorScheme(chrome.colorScheme)
        .background(PinwheelThemedWindow(theme: chrome.theme))
        .background(PinwheelShakeToShowBuild())
        .background(
            PinwheelFloatingControlsHost(
                chrome: chrome,
                tweakCount: chrome.tweakCount,
                fabVisible: chrome.isFloatingControlsVisible,
                colorScheme: chrome.colorScheme,
                theme: chrome.theme
            )
        )
        .onAppear {
            restoreThemes()
            normalizeSelection()
            restorePresentedItemIfNeeded()
        }
        .onChange(of: sections.map(\.id)) { _, _ in
            normalizeSelection()
        }
        .pinwheelTray(path: $displayPath) { axis in
            switch axis {
            case .section:
                PinTray("Section") {
                    PinTraySection {
                        ForEach(sections) { section in
                            PinTrayChoice(section.title, isChosen: section.id == selectedSection?.id) {
                                selectedSectionID = section.id
                                PinwheelStateStore.selectedSectionID = section.id
                                displayPath.removeAll()
                            }
                        }
                    }
                }

            case .theme:
                PinTray("Theme") {
                    PinTraySection {
                        ForEach(chrome.themes) { theme in
                            PinTrayChoice(theme.name, isChosen: theme == chrome.theme) {
                                chrome.selectTheme(theme)
                                displayPath.removeAll()
                            }
                            .environment(\.pinwheelTheme, theme)
                            .accessibilityIdentifier("pinwheel.theme.\(theme.id)")
                        }
                    }
                }

            case .appearance:
                PinTray("Appearance") {
                    PinTraySection {
                        ForEach(PinwheelAppearance.allCases) { appearance in
                            PinTrayChoice(appearance.title, isChosen: appearance == selectedAppearance) {
                                chrome.colorScheme = appearance.colorScheme
                                displayPath.removeAll()
                            }
                            .accessibilityIdentifier("pinwheel.appearance.\(appearance.rawValue)")
                        }
                    }
                }
            }
        }
        .sheet(item: $sheetItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
            .pinwheelPresented(chrome)
            .presentationDetents(detents(for: item.item.presentation))
        }
        .fullScreenCover(item: $fullscreenItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
            .pinwheelPresented(chrome)
        }
    }

    private var content: some SwiftUI.View {
        PinwheelIndexView(section: selectedSection, selectedItem: selectedItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    barTextButton(selectedSection?.title ?? "Pinwheel") {
                        displayPath = [.section]
                    }
                    .accessibilityIdentifier("pinwheel.sectionPicker")
                }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }
                if chrome.themes.count > 1 {
                    ToolbarItem(placement: .bottomBar) {
                        barSymbolButton("paintpalette", label: chrome.theme.name) {
                            displayPath = [.theme]
                        }
                        .accessibilityIdentifier("pinwheel.theme")
                    }
                    if #available(iOS 26, *) {
                        ToolbarSpacer(.fixed, placement: .bottomBar)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    barSymbolButton(selectedAppearance.icon, label: selectedAppearance.title) {
                        displayPath = [.appearance]
                    }
                    .accessibilityIdentifier("pinwheel.appearance")
                }
            }
            .tint(.actionText)
            .background(.primaryBackground)
    }

    private func barTextButton(_ title: String, action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            PinLabel(title).color(.action)
        }
    }

    private func barSymbolButton(
        _ symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Image(systemName: symbol)
                .font(PinTextStyle.body.font(in: chrome.theme))
                .symbolRenderingMode(.monochrome)
        }
        .accessibilityLabel(label)
    }

    private var selectedAppearance: PinwheelAppearance {
        PinwheelAppearance.allCases.first { $0.colorScheme == chrome.colorScheme } ?? .system
    }


    private var selectedSection: PinwheelSection? {
        if let selectedSectionID, let section = sections.first(where: { $0.id == selectedSectionID }) {
            return section
        }

        return sections.first
    }

    private func selectedItem(_ item: PinwheelItem) {
        guard let section = selectedSection else { return }
        present(item, in: section)
    }

    private func present(_ item: PinwheelItem, in section: PinwheelSection) {
        let selection = PinwheelSelection(sectionID: section.id, itemID: item.id)
        PinwheelStateStore.selectedSectionID = section.id
        PinwheelStateStore.selectedItemID = item.id

        let presentedItem = PresentedPinwheelItem(selection: selection, item: item)
        switch item.presentation {
        case .medium, .large:
            sheetItem = presentedItem
        case .fullscreen:
            fullscreenItem = presentedItem
        }
    }

    private func closePresentedItem() {
        fullscreenItem = nil
        sheetItem = nil
        PinwheelStateStore.clearSelectedItem()
    }

    private func restoreThemes() {
        chrome.themes = themes
        chrome.selectedThemeName = PinwheelStateStore.selectedThemeName
        chrome.normalizeTheme()
    }

    private func normalizeSelection() {
        guard !sections.isEmpty else {
            selectedSectionID = nil
            return
        }

        if let selectedSectionID, sections.contains(where: { $0.id == selectedSectionID }) {
            return
        }

        let sectionID = sections[0].id
        selectedSectionID = sectionID
        PinwheelStateStore.selectedSectionID = sectionID
    }

    private func restorePresentedItemIfNeeded() {
        guard !restoredSelection else { return }
        restoredSelection = true

        guard let sectionID = PinwheelStateStore.selectedSectionID,
              let itemID = PinwheelStateStore.selectedItemID,
              let section = sections.first(where: { $0.id == sectionID }),
              let item = section.items.first(where: { $0.id == itemID }) else {
            return
        }

        selectedSectionID = sectionID
        present(item, in: section)
    }

    private func detents(for presentation: PinwheelPresentation) -> Set<PresentationDetent> {
        switch presentation {
        case .medium:
            return [.medium]
        case .large, .fullscreen:
            return [.large]
        }
    }
}

private struct PinwheelIndexView: SwiftUI.View {
    let section: PinwheelSection?
    let selectedItem: (PinwheelItem) -> Void

    @State private var selectedTag: PinTag?
    @State private var scrolledDistance: CGFloat = 0
    @Environment(\.pinwheelTheme) private var theme

    var body: some SwiftUI.View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(groupedItems, id: \.letter) { group in
                        Section {
                            ForEach(group.items) { item in
                                SwiftUI.Button {
                                    selectedItem(item)
                                } label: {
                                    HStack {
                                        PinLabel(item.title.capitalizingFirstLetter)
                                        Spacer()
                                        ForEach(item.tags, id: \.self) { tag in
                                            PinLabel(tag.rawValue)
                                                .font(.caption)
                                                .color(.secondary)
                                                .padding(.horizontal, .spacing1)
                                                .padding(.vertical, .spacing1)
                                                .background(.secondaryBackground, in: Capsule())
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(item.id)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.primaryBackground)
                            }
                        } header: {
                            PinLabel(group.letter).font(.body).color(.secondary)
                                .textCase(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .listSectionSeparator(.hidden)
                        .id(group.letter)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.primaryBackground)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, distance in
                    scrolledDistance = distance
                }

                VStack(spacing: 2) {
                    ForEach(groupedItems, id: \.letter) { group in
                        SwiftUI.Button(group.letter) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(group.letter, anchor: .top)
                            }
                        }
                        .font(PinTextStyle.caption.font(in: theme))
                        .foregroundStyle(.actionText)
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if !tagsWorthFiltering.isEmpty {
                PinwheelFilterBar(
                    tags: tagsWorthFiltering,
                    selectedTag: $selectedTag,
                    scrolledDistance: scrolledDistance
                )
            }
        }
        .onChange(of: section?.id) { selectedTag = nil }
    }

    /// A tag earns a pill when filtering by it would leave something out — so a lone tag counts when the
    /// section also holds untagged items, and a tag every item carries does not.
    private var tagsWorthFiltering: [PinTag] {
        guard let section else { return [] }
        let tags = sectionTags
        if tags.count == 1, section.items.allSatisfy({ $0.tags == tags }) { return [] }
        return tags
    }

    private var sectionTags: [PinTag] {
        guard let section else { return [] }
        var ordered: [PinTag] = []
        for item in section.items {
            for tag in item.tags where !ordered.contains(tag) {
                ordered.append(tag)
            }
        }
        return ordered
    }

    private var groupedItems: [(letter: String, items: [PinwheelItem])] {
        guard let section else { return [] }

        let items = selectedTag.map { tag in
            section.items.filter { $0.tags.contains(tag) }
        } ?? section.items

        let groups = Dictionary(grouping: items) { item in
            String(item.title.capitalizingFirstLetter.prefix(1))
        }

        return groups.keys.sorted().map { key in
            (letter: key, items: groups[key] ?? [])
        }
    }
}




private struct PresentedPinwheelItem: Identifiable {
    let selection: PinwheelSelection
    let item: PinwheelItem

    var id: String {
        return selection.id
    }
}

enum PinwheelAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalizingFirstLetter }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }
}

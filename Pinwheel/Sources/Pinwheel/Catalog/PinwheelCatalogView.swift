import SwiftUI

struct PinwheelCatalogView: SwiftUI.View {
    let sections: [PinwheelSection]
    let usesEmbeddedNavigation: Bool

    @State private var selectedSectionID: String?
    @State private var showsSectionPicker = false
    @State private var fullscreenItem: PresentedPinwheelItem?
    @State private var sheetItem: PresentedPinwheelItem?
    @State private var restoredSelection = false
    @State private var chrome = PinwheelChrome()

    init(sections: [PinwheelSection], usesEmbeddedNavigation: Bool) {
        self.sections = sections
        self.usesEmbeddedNavigation = usesEmbeddedNavigation
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
        .background(
            PinwheelFloatingControlsHost(
                chrome: chrome,
                tweakCount: chrome.tweakCount,
                fabVisible: chrome.isFloatingControlsVisible
            )
        )
        .onAppear {
            normalizeSelection()
            restorePresentedItemIfNeeded()
        }
        .onChange(of: sections.map(\.id)) { _, _ in
            normalizeSelection()
        }
        .sheet(isPresented: $showsSectionPicker) {
            sectionPicker
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $sheetItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
            .environment(chrome)
            .presentationDetents(detents(for: item.item.presentation))
        }
        .fullScreenCover(item: $fullscreenItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
            .environment(chrome)
        }
    }

    private var content: some SwiftUI.View {
        PinwheelIndexView(section: selectedSection, selectedItem: selectedItem)
            .navigationTitle(selectedSection?.title ?? "Pinwheel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SwiftUI.Button {
                        showsSectionPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            PinLabel(selectedSection?.title ?? "Pinwheel").color(.action)
                            Image(systemName: "chevron.down")
                                .font(PinwheelTheme.Typography.footnote.weight(.medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.actionText)
                    .accessibilityIdentifier("pinwheel.sectionPicker")
                }
            }
            .background(.primaryBackground)
    }

    private var sectionPicker: some SwiftUI.View {
        NavigationStack {
            List(sections) { section in
                let isSelected = section.id == selectedSection?.id
                SwiftUI.Button {
                    selectedSectionID = section.id
                    PinwheelStateStore.selectedSectionID = section.id
                    showsSectionPicker = false
                } label: {
                    PinLabel(section.title).color(isSelected ? .action : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isSelected ? .actionText : .primaryText)
                .listRowSeparatorTint(.secondaryBackground)
                .listRowBackground(PinwheelTheme.Colors.primaryBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.primaryBackground)
            .navigationTitle("Sections")
            .navigationBarTitleDisplayMode(.inline)
        }
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

    private var fadeOpacity: Double {
        Double(min(1, max(0, scrolledDistance) / 24))
    }

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
                                                .padding(.horizontal, .spacingXS)
                                                .padding(.vertical, .spacingXXS)
                                                .background(.secondaryBackground, in: Capsule())
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(item.id)
                                .listRowSeparator(.hidden)
                                .listRowBackground(PinwheelTheme.Colors.primaryBackground)
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
                        .font(PinwheelTheme.Typography.caption)
                        .foregroundStyle(.actionText)
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if sectionTags.count > 1 {
                filterBar
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [
                                PinwheelTheme.Colors.primaryBackground,
                                PinwheelTheme.Colors.primaryBackground.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .offset(y: 24)
                        .opacity(fadeOpacity)
                        .allowsHitTesting(false)
                    }
            }
        }
        .onChange(of: section?.id) { selectedTag = nil }
    }

    private var filterBar: some SwiftUI.View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(sectionTags, id: \.self) { tag in
                    pill(title: tag.rawValue, isSelected: selectedTag == tag) {
                        selectedTag = selectedTag == tag ? nil : tag
                    }
                }
            }
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingS)
        }
        .background(.primaryBackground)
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            PinLabel(title)
                .color(isSelected ? .custom(PinwheelTheme.Colors.primaryBackground) : .primary)
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background {
                    if isSelected {
                        Capsule().fill(.actionText)
                    } else {
                        Capsule().strokeBorder(.secondaryText, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
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

import SwiftUI

struct PinwheelCatalogView: SwiftUI.View {
    let sections: [PinwheelSection]
    let usesEmbeddedNavigation: Bool

    @SwiftUI.State private var selectedSectionID: String?
    @SwiftUI.State private var showsSectionPicker = false
    @SwiftUI.State private var fullscreenItem: PresentedPinwheelItem?
    @SwiftUI.State private var sheetItem: PresentedPinwheelItem?
    @SwiftUI.State private var restoredSelection = false

    init(sections: [PinwheelSection], usesEmbeddedNavigation: Bool) {
        self.sections = sections
        self.usesEmbeddedNavigation = usesEmbeddedNavigation
        self._selectedSectionID = SwiftUI.State(initialValue: PinwheelStateStore.selectedSectionID)
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
        .onAppear {
            normalizeSelection()
            restorePresentedItemIfNeeded()
        }
        .onChange(of: sections.map(\.id)) { _ in
            normalizeSelection()
        }
        .sheet(isPresented: $showsSectionPicker) {
            sectionPicker
                .presentationDetents([.medium])
        }
        .sheet(item: $sheetItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
            .presentationDetents(detents(for: item.item.presentation))
        }
        .fullScreenCover(item: $fullscreenItem) { item in
            PinwheelPlayground(item: item.item, selection: item.selection) {
                closePresentedItem()
            }
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
                            Text(selectedSection?.title ?? "Pinwheel")
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                }
            }
            .background(SwiftUI.Color(uiColor: .primaryBackground))
    }

    private var sectionPicker: some SwiftUI.View {
        NavigationStack {
            List(sections) { section in
                SwiftUI.Button {
                    selectedSectionID = section.id
                    PinwheelStateStore.selectedSectionID = section.id
                    if let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) {
                        State.lastSelectedSection = sectionIndex
                    }
                    showsSectionPicker = false
                } label: {
                    HStack {
                        Text(section.title)
                        Spacer()
                        if section.id == selectedSection?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SwiftUI.Color(uiColor: .actionText))
                        }
                    }
                }
                .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
            }
            .scrollContentBackground(.hidden)
            .background(SwiftUI.Color(uiColor: .primaryBackground))
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

        if let sectionIndex = sections.firstIndex(where: { $0.id == section.id }),
           let itemIndex = section.items.firstIndex(where: { $0.id == item.id }) {
            State.lastSelectedIndexPath = IndexPath(row: itemIndex, section: sectionIndex)
        }

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

        let sectionID = sections[safe: State.lastSelectedSection]?.id ?? sections[0].id
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

    var body: some SwiftUI.View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(groupedItems, id: \.letter) { group in
                        Section(group.letter) {
                            ForEach(group.items) { item in
                                SwiftUI.Button {
                                    selectedItem(item)
                                } label: {
                                    Text(item.title.capitalizingFirstLetter)
                                        .font(.body)
                                        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .id(group.letter)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(SwiftUI.Color(uiColor: .primaryBackground))

                VStack(spacing: 2) {
                    ForEach(groupedItems, id: \.letter) { group in
                        SwiftUI.Button(group.letter) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(group.letter, anchor: .top)
                            }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SwiftUI.Color(uiColor: .actionText))
                    }
                }
                .padding(.trailing, 4)
            }
        }
    }

    private var groupedItems: [(letter: String, items: [PinwheelItem])] {
        guard let section else { return [] }

        let groups = Dictionary(grouping: section.items) { item in
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

import SwiftUI
import Pinwheel

struct SectionedListDemo: SwiftUI.View {
    @SwiftUI.State private var tasks = ["Draft the proposal", "Review the designs", "Ship the release", "Plan the next sprint"]

    var body: some SwiftUI.View {
        List {
            Section("Overview") {
                row("Status", "Active")
                row("Owner", "You")
            }
            Section("Preferences") {
                row("Notifications", "On")
                row("Appearance", "System")
                row("Privacy", "Standard")
            }
            Section("Tasks") {
                ForEach(tasks, id: \.self) { task in
                    row(task, "To do")
                }
                .onDelete { tasks.remove(atOffsets: $0) }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ title: String, _ detail: String) -> some SwiftUI.View {
        HStack {
            PinLabel(title).font(.body)
            Spacer()
            PinLabel(detail).font(.caption).color(.secondary)
        }
    }
}

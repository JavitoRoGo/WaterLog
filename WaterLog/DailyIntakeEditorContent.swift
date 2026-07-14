import SwiftData
import SwiftUI
import WidgetKit
import Playgrounds

struct DailyIntakeEditorContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
    @State private var saveError: String?
    @State private var showingAddSheet = false

    let date: Date
    let title: DailyIntakeEditorTitle
    let emptyTitle: LocalizedStringKey
    let emptyDescription: LocalizedStringKey?

    private var dayEntries: [WaterIntakeEntry] {
        IntakeAnalytics.entries(entries, on: date)
    }

    private var totalMilliliters: Int {
        dayEntries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            DailyProgressSection(totalMilliliters: totalMilliliters, addEntry: addEntry)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 16, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            Section {
                ForEach(dayEntries) { entry in
                    IntakeEntryRow(entry: entry)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(entry)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if dayEntries.isEmpty {
                ContentUnavailableView(emptyTitle, systemImage: "drop", description: emptyDescription.map { Text($0) })
                    .offset(y: 180)
            }
        }
        .dailyIntakeNavigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWaterEntryView(initialDate: date)
        }
        .alert("Error while saving", isPresented: errorBinding) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { isPresented in
                if !isPresented {
                    saveError = nil
                }
            }
        )
    }

    private func addEntry(amount: Int) {
        let entry = WaterIntakeEntry(date: entryDate(), amount: amount)
        modelContext.insert(entry)
        saveChanges(affecting: entry.date)
    }

    private func delete(_ entry: WaterIntakeEntry) {
        let entryDate = entry.date
        modelContext.delete(entry)
        saveChanges(affecting: entryDate)
    }

    private func saveChanges(affecting date: Date) {
        do {
            try modelContext.save()
            IntakeAnalytics.reloadWidgetTimelineIfNeeded(for: date)
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func entryDate(calendar: Calendar = .current) -> Date {
        if calendar.isDateInToday(date) {
            return .now
        }

        let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
        return calendar.date(
            bySettingHour: time.hour ?? 12,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: date
        ) ?? date
    }
}

enum DailyIntakeEditorTitle {
    case localized(LocalizedStringResource)
    case formatted(String)
}

private struct DailyIntakeNavigationTitleModifier: ViewModifier {
    let title: DailyIntakeEditorTitle

    func body(content: Content) -> some View {
        switch title {
        case .localized(let title):
            content.navigationTitle(title)
        case .formatted(let title):
            content.navigationTitle(title)
        }
    }
}

private extension View {
    func dailyIntakeNavigationTitle(_ title: DailyIntakeEditorTitle) -> some View {
        modifier(DailyIntakeNavigationTitleModifier(title: title))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WaterIntakeEntry.self, configurations: config)
    
    // Añadimos una entrada para que no aparezca la vista de "Sin registros"
    let entry = WaterIntakeEntry(date: .now, amount: 500)
    container.mainContext.insert(entry)

    return NavigationStack {
        DailyIntakeEditorContent(
            date: .now,
            title: .localized("Today"),
            emptyTitle: "No entries",
            emptyDescription: "Add some water entries"
        )
    }
    .modelContainer(container)
}

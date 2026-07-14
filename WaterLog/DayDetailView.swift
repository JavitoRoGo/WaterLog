import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    var body: some View {
        DailyIntakeEditorContent(
            date: date,
            title: .formatted(WaterLogFormatters.shortDayAndMonth(date)),
            emptyTitle: "No entry",
            emptyDescription: "Add some water entries"
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WaterIntakeEntry.self, configurations: config)
    
    return NavigationStack {
        DayDetailView(date: .now)
    }
    .modelContainer(container)
}


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
    DayDetailView(date: .now)
		.previewContainer(days: 1)
}

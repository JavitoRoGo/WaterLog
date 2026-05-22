import SwiftUI

struct DayDetailView: View {
    let date: Date

    var body: some View {
        DailyIntakeEditorContent(
            date: date,
            title: WaterLogFormatters.shortDayAndMonth(date),
            emptyTitle: "Sin registros",
            emptyDescription: "Añade una cantidad para este día."
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

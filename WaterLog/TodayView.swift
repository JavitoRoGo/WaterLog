import SwiftData
import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            DailyIntakeEditorContent(
                date: .now,
                title: "Hoy",
                emptyTitle: "Sin registros hoy",
                emptyDescription: "Añade una cantidad para empezar el día."
            )
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

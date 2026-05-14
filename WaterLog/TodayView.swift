import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDate = Date.now

    var body: some View {
        NavigationStack {
            DailyIntakeEditorContent(
                date: currentDate,
                title: title,
                emptyTitle: "Sin registros hoy",
                emptyDescription: "Añade una cantidad para empezar el día."
            )
        }
        .task {
            await refreshDateAtDayBoundaries()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshCurrentDate()
        }
    }

    private var title: String {
        let weekday = WaterLogFormatters.weekday(currentDate)
        let day = currentDate.formatted(.dateTime.day().locale(IntakeConstants.spanishLocale))
        return "Hoy, \(weekday) \(day)"
    }

    private func refreshDateAtDayBoundaries(calendar: Calendar = .current) async {
        refreshCurrentDate()

        while !Task.isCancelled {
            guard let nextDay = calendar.nextDate(
                after: .now,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) else {
                return
            }

            let secondsUntilNextDay = max(1, Int64(ceil(nextDay.timeIntervalSinceNow)))

            do {
                try await Task.sleep(for: .seconds(secondsUntilNextDay))
                refreshCurrentDate()
            } catch {
                return
            }
        }
    }

    private func refreshCurrentDate() {
        currentDate = .now
    }
}

#Preview {
    TodayView()
        .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

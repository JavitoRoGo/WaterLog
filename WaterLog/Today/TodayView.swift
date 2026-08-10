import SwiftData
import SwiftUI

struct TodayView: View {
	private enum TabToShow {
		case historical, achievements, insights, settings
	}
	
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDate = Date.now
	@State private var tabToShow: TabToShow?

    var body: some View {
        NavigationStack {
            DailyIntakeEditorContent(
                date: currentDate,
                title: .localized(title),
                emptyTitle: "No entries today",
                emptyDescription: "Add some water to stay hydrated!"
            )
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Menu {
						Button("Historical", systemImage: "chart.bar.xaxis") {
							tabToShow = .historical
						}
						Button("Achievements", systemImage: "trophy") {
							tabToShow = .achievements
						}
						Button("Insights", systemImage: "chart.xyaxis.line") {
							tabToShow = .insights
						}
						Button("Settings", systemImage: "gearshape") {
							tabToShow = .settings
						}
					} label: {
						Image(systemName: "list.bullet")
					}
				}
			}
			.navigationDestination(item: $tabToShow) { tab in
				switch tab {
				case .historical: StatisticsView()
				case .achievements: StreaksView()
				case .insights: InsightsView()
				case .settings: SettingsView()
				}
			}
        }
        .task {
            await refreshDateAtDayBoundaries()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshCurrentDate()
        }
    }

    private var title: LocalizedStringResource {
        let weekday = WaterLogFormatters.weekday(currentDate)
        let day = currentDate.formatted(.dateTime.day().locale(IntakeConstants.appLocale))
        return "Today, \(weekday) \(day)"
    }

    private func refreshDateAtDayBoundaries(calendar: Calendar = .current) async { // Añadido valor por defecto al parámetro para evitar errores en la llamada
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
		.previewContainer(days: 1)
}

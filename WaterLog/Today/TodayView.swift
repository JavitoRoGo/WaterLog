import SwiftData
import SwiftUI

struct TodayView: View {
	private enum TabToShow: Identifiable, CaseIterable {
		case today, historical, achievements, insights, settings
		
		var id: Self { self }
		
		var text: LocalizedStringResource {
			switch self {
			case .today: "Today"
			case .historical: "Historical"
			case .achievements: "Achievements"
			case .insights: "Insights"
			case .settings: "Settings"
			}
		}
		
		var icon: String {
			switch self {
				case .today: "drop"
			case .historical: "chart.bar.xaxis"
			case .achievements: "trophy"
			case .insights: "chart.xyaxis.line"
			case .settings: "gearshape"
			}
		}
		
		@ViewBuilder
		func makeView(title: LocalizedStringResource) -> some View {
			switch self {
			case .today: DailyIntakeEditorContent(
				date: Date.now,
				title: .localized(title),
				emptyTitle: "No entries today",
				emptyDescription: "Add some water to stay hydrated!"
			)
			case .historical: StatisticsView()
			case .achievements: StreaksView()
			case .insights: InsightsView()
			case .settings: SettingsView()
			}
		}
	}
	
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDate = Date.now
	@State private var tabToShow: TabToShow = .today

    var body: some View {
        NavigationStack {
			tabToShow.makeView(title: title)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Menu {
						ForEach(TabToShow.allCases) { tab in
							Button {
								tabToShow = tab
							} label: {
								Label(tab.text, systemImage: tab.icon)
							}
						}
					} label: {
						Image(systemName: "list.bullet")
					}
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

import SwiftUI

struct MonthDetailView: View {
    let month: MonthIntakeSummary
    let entries: [WaterIntakeEntry]
	let goals: [DailyGoal] // Añadido para tener acceso a los objetivos específicos
	let defaultGoal: Int   // Añadido para el objetivo base

	private var dailySummaries: [DailyIntakeSummary] {
		let interval = Calendar.current.dateInterval(of: .month, for: month.monthStart)
		let endDate = min(interval?.end.addingTimeInterval(-1) ?? month.monthStart, .now)

		// Actualizado para incluir goals y defaultGoal según la nueva firma de IntakeAnalytics
		return IntakeAnalytics.dailySummaries(
			for: entries,
			goals: goals,
			defaultGoal: defaultGoal,
			from: interval?.start ?? month.monthStart,
			through: endDate
		)
	}

    var body: some View {
        List(dailySummaries.reversed()) { summary in
            NavigationLink(value: summary) {
                DailySummaryRow(summary: summary)
            }
        }
        .navigationTitle(WaterLogFormatters.month(month.monthStart).capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DailyIntakeSummary.self) { summary in
            DayDetailView(date: summary.date)
        }
    }
}

struct YearDetailView: View {
    let year: YearIntakeSummary
    let entries: [WaterIntakeEntry]
	let goals: [DailyGoal] // Añadido para tener acceso a los objetivos específicos
	let defaultGoal: Int   // Añadido para el objetivo base

	private var monthSummaries: [MonthIntakeSummary] {
		let interval = Calendar.current.dateInterval(of: .year, for: year.yearStart)
		let endDate = min(interval?.end.addingTimeInterval(-1) ?? year.yearStart, .now)
		
		// Actualizado para incluir goals y defaultGoal según la nueva firma de IntakeAnalytics
		return IntakeAnalytics.monthSummaries(
			for: entries,
			goals: goals,
			defaultGoal: defaultGoal,
			from: interval?.start ?? year.yearStart,
			through: endDate
		)
	}

	var body: some View {
		NavigationStack {
			List(monthSummaries.reversed()) { summary in
				NavigationLink(value: summary) {
					MonthSummaryRow(summary: summary)
				}
			}
			.navigationTitle(WaterLogFormatters.year(year.yearStart))
			.navigationBarTitleDisplayMode(.inline)
			.navigationDestination(for: MonthIntakeSummary.self) { summary in
				MonthDetailView(month: summary, entries: entries, goals: goals, defaultGoal: defaultGoal)
			}
		}
	}
}

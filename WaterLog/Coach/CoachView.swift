import SwiftUI
import SwiftData

struct CoachView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
	@Query(sort: \DailyGoal.date, order: .forward) private var goals: [DailyGoal]
	
	@AppStorage(
		WaterLogStore.keyForStandardGoalMilliliters,
		store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
	) private var defaultGoal: Int = IntakeConstants.defaultGoalMilliliters
	
    @State private var analysisPeriod: AnalysisPeriod = .lastMonth
	
    // El contexto que alimenta la inteligencia de la vista
    private var coachingContext: CoachingContext {
        CoachAnalytics.generateCoachingContext(from: summaries, daysToAnalyze: analysisPeriod)
    }
	
	private var summaries: [DailyIntakeSummary] {
		getAllDailySummaries()
	}

    var body: some View {
        NavigationStack {
        	ScrollView {
				VStack(spacing: 20) {
					// Coach Hero Section
					CoachHeroSection(motivationTag: coachingContext.summary.primaryMotivationTag)
					
					// Quick Stats Grid
					StatsGrid(coachingContext: coachingContext)
					
					// Detailed Patterns
					PatternsSection(coachingContext: coachingContext)
				}
				.padding()
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Menu {
						Picker("Period", selection: $analysisPeriod) {
							ForEach(AnalysisPeriod.allCases) { period in
								Text(period.periodLabel).tag(period)
							}
						}
					} label: {
						Label("Period", systemImage: "calendar")
					}
				}
			}
        }
    }

    // MARK: - Helpers
	
	private func getAllDailySummaries() -> [DailyIntakeSummary] {
		let calendar = Calendar.current
		// Buscamos la fecha más antigua de todas las entradas para no perder nada
		let startDate = entries.map(\.date).min() ?? .now
		
		return IntakeAnalytics.dailySummaries(
			for: entries,
			goals: goals,
			defaultGoal: defaultGoal,
			from: startDate,
			through: .now,
			calendar: calendar
		)
	}
}

#Preview {
	CoachView()
		.previewContainer(days: 20)
}

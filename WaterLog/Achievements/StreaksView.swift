import SwiftUI
import SwiftData

struct StreaksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
    @Query(sort: \DailyGoal.date, order: .forward) private var goals: [DailyGoal]
    
    @AppStorage(
        WaterLogStore.keyForStandardGoalMilliliters,
        store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
    ) private var defaultGoal: Int = IntakeConstants.defaultGoalMilliliters

    var body: some View {
		let summaries = getDailySummaries()
		
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // 1. Card de Racha Actual (Evolución)
					CurrentStreakCard(summaries: summaries)
                    
                    // 2. Sección de Récord Histórico
					LongestStreakSection(summaries: summaries)
                    
                    // 3. Galería de Logros
					AchievementsGrid(summaries: summaries)
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }
	
	// MARK: - Helpers

    private func getDailySummaries() -> [DailyIntakeSummary] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: .now) ?? .now
        
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
	StreaksView()
		.previewContainer(days: 30)
}

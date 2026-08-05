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
	let config = ModelConfiguration(isStoredInMemoryOnly: true)
	let container = try! ModelContainer(for: WaterIntakeEntry.self, DailyGoal.self, configurations: config)
	
	let context = container.mainContext
	let calendar = Calendar.current
	let today = calendar.startOfDay(for: .now)

	// 1. Creamos un objetivo diario para los próximos 40 días para asegurar logros de largo plazo
	for i in 0..<40 {
		if let date = calendar.date(byAdding: .day, value: -i, to: today) {
			let goal = DailyGoal(date: date, amount: 2000)
			context.insert(goal)
			
			// 2. Registramos entradas de agua para cumplir el objetivo en cada uno de esos días
			// Esto garantiza que se generen bloques de cumplimiento (rachas)
			let entry = WaterIntakeEntry(date: date, amount: 2500)
			context.insert(entry)
		}
	}

	return NavigationStack {
		StreaksView()
			.modelContainer(container)
	}
}

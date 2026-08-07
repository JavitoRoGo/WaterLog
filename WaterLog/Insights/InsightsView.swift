import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
    @Query(sort: \DailyGoal.date, order: .forward) private var goals: [DailyGoal]
    
    @AppStorage(
        WaterLogStore.keyForStandardGoalMilliliters,
        store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
    ) private var defaultGoal: Int = IntakeConstants.defaultGoalMilliliters
	
	var body: some View {
        let summaries = getAllDailySummaries()
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Tendencia de Consumo
                    ConsumptionTrendSection(summaries: summaries)
                    
                    // 2. Evolución Semanal
                    WeeklyEvolutionSection(summaries: summaries)
                    
                    // 3. Índice de Estabilidad (Placeholder)
                    StabilitySection(summaries: summaries)
                    
                    // 4. Cumplimiento del Objetivo (Placeholder)
					GoalSuccessRateSection(summaries: summaries)
                    
                    // 5. Predicción de Riesgo (Placeholder)
                    insightPlaceholder(title: "Predictive Insights", subtitle: "Coming soon...")
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Placeholders & Helpers

    @ViewBuilder
    private func insightPlaceholder(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

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
    InsightsView()
		.previewContainer(days: 20)
}

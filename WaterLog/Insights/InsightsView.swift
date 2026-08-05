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
        let summaries = getDailySummaries()
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Tendencia de Consumo (Implementada)
                    ConsumptionTrendSection(summaries: summaries)
                    
                    // 2. Evolución Semanal (Placeholder)
                    insightPlaceholder(title: "Weekly Evolution", subtitle: "Coming soon...")
                    
                    // 3. Índice de Estabilidad (Placeholder)
                    insightPlaceholder(title: "Stability Index", subtitle: "Coming soon...")
                    
                    // 4. Cumplimiento del Objetivo (Placeholder)
                    insightPlaceholder(title: "Goal Success Rate", subtitle: "Coming soon...")
                    
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

    private func getDailySummaries() -> [DailyIntakeSummary] {
        let calendar = Calendar.current
        // Usamos un rango amplio para asegurar que tenemos los 30 días necesarios
        let startDate = calendar.date(byAdding: .month, value: -2, to: .now) ?? .now
        
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
    
    // Mock data para probar la tendencia (Mejorando)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    for i in 0..<40 {
        if let date = calendar.date(byAdding: .day, value: -i, to: today) {
            // Los últimos 7 días bebemos mucho (3000ml), el resto menos (1500ml)
            let amount = i < 7 ? 3000 : 1500
            context.insert(WaterIntakeEntry(date: date, amount: amount))
        }
    }

    return NavigationStack {
        InsightsView()
            .modelContainer(container)
    }
}

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
    @State private var isGeneratingAdvice = false
    @State private var coachMessage: String = ""
    
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
					CoachHeroSection(coachColor: coachColor, coachIcon: coachIcon, coachMessage: coachMessage, isGeneratingAdvice: isGeneratingAdvice)
					
					// Quick Stats Grid
					StatsGrid(coachingContext: coachingContext, coachIconText: coachIconText)
					
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
        .task {
            // Simulamos la llamada al LLM local al cargar la vista
            await fetchCoachAdvice()
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

    private func fetchCoachAdvice() async {
        isGeneratingAdvice = true
        
        // Simulamos el tiempo de respuesta de un LLM local (Foundation Models)
        // En la implementación real, aquí llamarías al modelo pasándole coachingContext
        try? await Task.sleep(for: .seconds(1.5))
        
        // Ejemplo de cómo el mensaje cambiaría según el contexto generado
        switch coachingContext.summary.primaryMotivationTag {
        case .celebratory:
            coachMessage = "You're on fire! Your hydration streak is growing beautifully. Keep this momentum!"
        case .urgent:
            coachMessage = "Warning: We've noticed a drop in your consistency. Let's try to hit your goal today!"
        case .encouraging:
            coachMessage = "You're doing well, but let's try to make your drinking habits even more regular."
        case .neutral:
            coachMessage = "Ready for today? Your hydration levels are looking steady."
        }
        
        isGeneratingAdvice = false
    }

    private var coachColor: Color {
        switch coachingContext.summary.primaryMotivationTag {
        case .celebratory: return .orange
        case .urgent: return .red
        case .encouraging: return .blue
        case .neutral: return .secondary
        }
    }

	private var coachIcon: String {
        switch coachingContext.summary.primaryMotivationTag {
        case .celebratory: return "sparkles"
        case .urgent: return "exclamationmark.triangle.fill"
        case .encouraging: return "leaf.fill"
        case .neutral: return "person.fill"
        }
    }

	private var coachIconText: String {
        switch coachingContext.metrics.consumptionTrend {
        case .increasing: return "Up"
        case .decreasing: return "Down"
        case .stable: return "Steady"
        case .unknown: return "--"
        }
    }
}

#Preview {
	CoachView()
		.previewContainer(days: 20)
}

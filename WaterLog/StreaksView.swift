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
					currentStreakCard(summaries: summaries)
                    
                    // 2. Sección de Récord Histórico
					longestStreakSection(summaries: summaries)
                    
                    // 3. Galería de Logros
					achievementsGrid(summaries: summaries)
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }

    // MARK: - Subviews

    private func currentStreakCard(summaries: [DailyIntakeSummary]) -> some View {
        let streakInfo = Streaks.calculateStreaks(from: summaries)
        
        return VStack(spacing: 20) {
            Text(streakInfo.currentEvolution.emoji)
                .font(.system(size: 60))
                .shadow(radius: 5)
            
            VStack(spacing: 4) {
				AnimatedCounterView(targetValue: streakInfo.currentStreak)
				
                Text("Current streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
			
			VStack(spacing: 8) {
				EvolutionProgressView(currentStreak: streakInfo.currentStreak)
				
				// Texto de motivación opcional basado en la evolución
				Text(streakInfo.currentEvolution.evolutionMotivation)
					.font(.caption2.weight(.medium))
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
			}
			.padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

	private func longestStreakSection(summaries: [DailyIntakeSummary]) -> some View {
		let streakInfo = Streaks.calculateStreaks(from: summaries)
		let maxRecord = Streaks.calculateExtremeRecords(from: summaries)
		let maxMonthly = Streaks.calculateMaxMonthlyIntake(from: summaries)
		
		return VStack(alignment: .leading, spacing: 12) {
			// --- SUBSECCIÓN: MEJOR RACHA ---
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					Image(systemName: "trophy.fill")
						.foregroundStyle(.orange)
					Text("Best streak: \(streakInfo.longestStreak) days")
						.font(.headline)
				}
				
				if let range = streakInfo.longestStreakRange {
					let startStr = range.lowerBound.formatted(date: .numeric, time: .omitted)
					let endStr = range.upperBound.formatted(date: .numeric, time: .omitted)
					Text("\(startStr) - \(endStr)")
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
			
			Divider()
			
			// --- SUBSECCIÓN: MÁXIMA INGESTA ---
			if let record = maxRecord {
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Image(systemName: "drop.fill")
							.foregroundStyle(.blue)
						Text("Max daily intake: \(WaterLogFormatters.volumeFromMilliliters(record.totalMilliliters))")
							.font(.headline)
					}
					
					Text(record.date.formatted(date: .numeric, time: .omitted))
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
			
			Divider()

			// --- SUBSECCIÓN: MÁXIMA INGESTA (MES) ---
			if let monthly = maxMonthly {
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Image(systemName: "calendar.badge.clock")
							.foregroundStyle(.purple)
						Text("Best month: \(WaterLogFormatters.largeVolumeFromMilliliters(monthly.totalMilliliters))")
							.font(.headline)
					}
					
					// Mostramos el nombre del mes (ej: "octubre 2023")
					Text(monthly.month.formatted(.dateTime.month(.wide).year()))
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 16)
				.strokeBorder(.orange.opacity(0.3), lineWidth: 1)
		)
	}

    private func achievementsGrid(summaries: [DailyIntakeSummary]) -> some View {
        let achievements = Streaks.calculateHistoricalAchievements(from: summaries)
        
		return VStack {
			if achievements.isEmpty {
				VStack(spacing: 10) {
					Image(systemName: "medal.fill")
						.font(.largeTitle)
						.foregroundStyle(.secondary)
					Text("No achievements yet")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.padding(.top, 40)
			} else {
				VStack(alignment: .leading) {
					Text("Your Medals")
						.font(.title2.bold())
						.padding(.bottom, 5)
					
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
						ForEach(achievements) { achievement in
							AchievementCard(achievement: achievement)
						}
					}
				}
			}
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

/// Una tarjeta individual para cada logro en la cuadrícula
struct AchievementCard: View {
    let achievement: HistoricalAchievement
    
	var body: some View {
		VStack(spacing: 12) {
			Text(achievement.type.emoji)
				.font(.system(size: 40))
			
			VStack(spacing: 2) {
				Text(achievement.type.displayName)
					.font(.system(size: 14, weight: .bold))
					.multilineTextAlignment(.center)
					.lineLimit(2)
				
				Text(achievement.type.requirementDescription)
					.font(.system(size: 10))
					.foregroundStyle(.secondary)
			}
			
			Text("x\(achievement.count)")
				.fontWeight(.semibold)
				.foregroundStyle(.blue)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(uiColor: .tertiarySystemBackground))
				.shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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

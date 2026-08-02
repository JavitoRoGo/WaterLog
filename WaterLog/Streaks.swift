import Foundation

/// Representa los resultados del cálculo de rachas actuales.
struct StreakResults {
    let currentStreak: Int
    let longestStreak: Int
	let longestStreakRange: ClosedRange<Date>?
    let currentEvolution: ConsistencyEvolution // El estado "vivo" de la racha
}

/// Define en qué etapa de crecimiento se encuentra la racha actual.
enum ConsistencyEvolution: Int, CaseIterable {
    case none = 0        // 0-2 días
    case initiator = 3   // 3-6 días
    case constant = 7    // 7-29 días
    case master = 30     // 30+ días

    /// Emoji que representa visualmente el estado de la racha.
    var emoji: String {
        switch self {
        case .none: return "🥵"       // Un inicio oscuro o vacío
        case .initiator: return "🌱"  // Un brote pequeño
        case .constant: return "🌿"   // Una planta creciendo
        case .master: return "🌳"     // Un árbol fuerte y establecido
        }
    }
	
	var evolutionMotivation: LocalizedStringResource {
		switch self {
		case .none: return "Start your journey"
		case .initiator: return "Keep growing!"
		case .constant: return "Almost a Master..."
		case .master: return "Legendary status reached! 🌟"
		}
	}
}

/// Representa un logro histórico de la galería del usuario.
struct HistoricalAchievement: Identifiable, Hashable {
    let id = UUID()
    let type: AchievementType
    let count: Int
}

/// Tipos de logros que se guardan en la galería.
enum AchievementType: CaseIterable {
    case hydrationConstant // Bloques de 7 días
    case waterMaster       // Bloques de 30 días

    /// Nombre localizado para mostrar en la interfaz de usuario.
    var displayName: LocalizedStringResource {
        switch self {
        case .hydrationConstant: return "Hydration Constant"
        case .waterMaster: return "Water Master"
        }
    }
	
	/// Descripción corta del requisito para dar contexto al usuario.
	var requirementDescription: LocalizedStringResource {
		switch self {
		case .hydrationConstant: return "7-day streak"
		case .waterMaster: return "30-day streak"
		}
	}

    /// Emoji que representa la medalla ganada en la galería.
    var emoji: String {
        switch self {
        case .hydrationConstant: return "💧"
        case .waterMaster: return "🌊"
        }
    }
}

struct MonthlyRecord {
	let month: Date // El primer día del mes que registró el máximo
	let totalMilliliters: Int
}

enum Streaks {
	
	// MARK: - Constants
	private enum Thresholds {
		static let initiatorDays = ConsistencyEvolution.initiator.rawValue
		static let constantDays = ConsistencyEvolution.constant.rawValue
		static let masterDays = ConsistencyEvolution.master.rawValue
	}
	
	// MARK: - Main Calculation
	
	/// Calcula todo lo relacionado con rachas y evolución actual.
	static func calculateStreaks(from dailySummaries: [DailyIntakeSummary]) -> StreakResults {
		guard !dailySummaries.isEmpty else {
			return StreakResults(currentStreak: 0, longestStreak: 0, longestStreakRange: nil, currentEvolution: .none)
		}
		
		let sortedSummaries = dailySummaries.sorted { $0.date < $1.date }
		let complianceHistory = sortedSummaries.map { $0.reachedGoal }
		let datesHistory = sortedSummaries.map { $0.date }
		
		let current = calculateCurrentStreak(complianceHistory: complianceHistory, datesHistory: datesHistory)
		// Ahora obtenemos tanto el número como el rango
		let (longest, longestRange) = calculateLongestStreakWithDates(summaries: sortedSummaries)
		
		let evolution: ConsistencyEvolution = {
			if current >= Thresholds.masterDays { return .master }
			if current >= Thresholds.constantDays { return .constant }
			if current >= Thresholds.initiatorDays { return .initiator }
			return .none
		}()
		
		return StreakResults(
			currentStreak: current,
			longestStreak: longest,
			longestStreakRange: longestRange, // Pasamos el rango
			currentEvolution: evolution
		)
	}
	
	/// Calcula los logros de la galería basados en el historial completo.
	static func calculateHistoricalAchievements(from dailySummaries: [DailyIntakeSummary]) -> [HistoricalAchievement] {
		guard !dailySummaries.isEmpty else { return [] }
		
		let sortedSummaries = dailySummaries.sorted { $0.date < $1.date }
		let complianceHistory = sortedSummaries.map { $0.reachedGoal }
		
		// 1. Encontrar todos los bloques de días consecutivos cumplidos
		let blocks = findConsecutiveComplianceBlocks(complianceHistory: complianceHistory)
		
		var achievements: [HistoricalAchievement] = []
		
		// 2. Calcular logros para "Hydration Constant" (7 días)
		let constantCount = blocks.reduce(0) { count, blockLength in
			count + (blockLength / Thresholds.constantDays)
		}
		if constantCount > 0 {
			achievements.append(HistoricalAchievement(type: .hydrationConstant, count: constantCount))
		}
		
		// 3. Calcular logros para "Water Master" (30 días)
		let masterCount = blocks.reduce(0) { count, blockLength in
			count + (blockLength / Thresholds.masterDays)
		}
		if masterCount > 0 {
			achievements.append(HistoricalAchievement(type: .waterMaster, count: masterCount))
		}
		
		return achievements
	}
	
	// MARK: - Private Helpers
	
	/// Divide la historia de cumplimiento en bloques de días consecutivos (ej: [true, true, false, true] -> [2, 1])
	private static func findConsecutiveComplianceBlocks(complianceHistory: [Bool]) -> [Int] {
		var blocks: [Int] = []
		var currentBlockLength = 0
		
		for isCompliant in complianceHistory {
			if isCompliant {
				currentBlockLength += 1
			} else {
				if currentBlockLength > 0 {
					blocks.append(currentBlockLength)
				}
				currentBlockLength = 0
			}
		}
		// Añadir el último bloque si la historia termina en cumplimiento
		if currentBlockLength > 0 {
			blocks.append(currentBlockLength)
		}
		
		return blocks
	}
	
	private static func calculateCurrentStreak(complianceHistory: [Bool], datesHistory: [Date]) -> Int {
		guard let lastIndex = complianceHistory.indices.last else { return 0 }
		
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		var index = lastIndex
		
		let lastDate = datesHistory[lastIndex]
		let isLastRecordToday = calendar.isDate(lastDate, inSameDayAs: today)
		
		if isLastRecordToday && !complianceHistory[index] {
			index -= 1
		}
		
		var currentStreak = 0
		while index >= 0 && complianceHistory[index] {
			currentStreak += 1
			index -= 1
		}
		
		return currentStreak
	}
	
	private static func calculateLongestStreakWithDates(summaries: [DailyIntakeSummary]) -> (Int, ClosedRange<Date>?) {
		var maxStreak = 0
		var longestRange: ClosedRange<Date>? = nil
		
		var currentRunningStreak = 0
		var currentStartDate: Date? = nil
		
		for summary in summaries {
			if summary.reachedGoal {
				if currentRunningStreak == 0 {
					currentStartDate = summary.date
				}
				currentRunningStreak += 1
				
				// Si acabamos de superar el récord anterior o igualarlo con una racha nueva
				if currentRunningStreak > maxStreak {
					maxStreak = currentRunningStreak
					if let start = currentStartDate {
						longestRange = start...summary.date
					}
				}
			} else {
				currentRunningStreak = 0
				currentStartDate = nil
			}
		}
		
		return (maxStreak, longestRange)
	}
	
	/// Calcula la máxima ingesta diaria
	static func calculateExtremeRecords(from summaries: [DailyIntakeSummary]) -> DailyIntakeSummary? {
		guard !summaries.isEmpty else { return nil }
		
		// Comparamos primero por mililitros.
		// Si los mililitros son iguales, comparamos por fecha para que el más reciente sea el ganador.
		let maxRecord = summaries.max { a, b in
			if a.totalMilliliters != b.totalMilliliters {
				return a.totalMilliliters < b.totalMilliliters
			} else {
				return a.date < b.date
			}
		}
		
		return maxRecord
	}
	
	static func calculateMaxMonthlyIntake(from summaries: [DailyIntakeSummary], calendar: Calendar = .current) -> MonthlyRecord? {
		guard !summaries.isEmpty else { return nil }
		
		// 1. Agrupar por mes
		let groupedByMonth = Dictionary(grouping: summaries) { summary in
			calendar.date(from: calendar.dateComponents([.year, .month], from: summary.date)) ?? summary.date
		}
		
		// 2. Calcular el total de cada mes
		let monthlyTotals = groupedByMonth.map { (monthStart, dailySummaries) in
			let total = dailySummaries.reduce(0) { $0 + $1.totalMilliliters }
			return MonthlyRecord(month: monthStart, totalMilliliters: total)
		}
		
		// 3. Encontrar el mes con el máximo (usando la misma lógica de desempate que antes)
		let maxMonth = monthlyTotals.max { a, b in
			if a.totalMilliliters != b.totalMilliliters {
				return a.totalMilliliters < b.totalMilliliters
			} else {
				return a.month < b.month
			}
		}
		
		return maxMonth
	}
}

import Foundation
import WidgetKit

enum IntakeConstants {
    // Este valor se usará solo como respaldo extremo si no hay nada en AppStorage,
    static let defaultGoalMilliliters = 2_000
    static let appLocale = Locale.autoupdatingCurrent
}

enum StatisticsPeriod: CaseIterable, Identifiable {
    case sevenDays
    case oneYear
    case total

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .sevenDays:
            "7 days"
        case .oneYear:
            "1 year"
        case .total:
            "Total"
        }
    }
}

enum AnalysisPeriod: Int, CaseIterable, Identifiable {
	case lastWeek = 7    // 7 días
	case lastMonth = 30   // 30 días
	case lastYear = 365    // 365 días
	case allTime = 0    // Todo el histórico
	
	var id: Self { self }
	
	var periodLabel: LocalizedStringResource {
		switch self {
		case .lastWeek:
			"Last 7 days"
		case .lastMonth:
			"Last 30 days"
		case .lastYear:
			"Last year"
		case .allTime:
			"All time"
		}
	}
}

enum RiskLevel {
	case low, medium, high
}

enum IntakeAnalytics {
    static func progress(for totalMilliliters: Int, goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(totalMilliliters) / Double(goal), 1)
    }

    static func percentage(for totalMilliliters: Int, goal: Int) -> Int {
        guard goal > 0 else { return 0 }
        return Int((Double(totalMilliliters) / Double(goal) * 100).rounded())
    }

    static func entries(_ entries: [WaterIntakeEntry], on day: Date, calendar: Calendar = .current) -> [WaterIntakeEntry] {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    static func totalMilliliters(_ entries: [WaterIntakeEntry], on day: Date, calendar: Calendar = .current) -> Int {
        self.entries(entries, on: day, calendar: calendar).reduce(0) { $0 + $1.amount }
    }

    /// Calcula los resúmenes diarios teniendo en cuenta los objetivos específicos de cada día o el objetivo por defecto.
    static func dailySummaries(
        for entries: [WaterIntakeEntry],
        goals: [DailyGoal],
        defaultGoal: Int,
        from startDate: Date,
        through endDate: Date,
        calendar: Calendar = .current
    ) -> [DailyIntakeSummary] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        // Mapeamos los objetivos por fecha para búsqueda rápida O(1)
        let goalsByDate = Dictionary(uniqueKeysWithValues: goals.map { 
            (calendar.startOfDay(for: $0.date), $0.amount) 
        })
        
        let groupedTotals = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        var summaries: [DailyIntakeSummary] = []
        var current = start

        while current <= end {
            let total = groupedTotals[current, default: 0]
            // Lógica del punto 2: Buscar objetivo específico o usar el por defecto
            let goalForDay = goalsByDate[current] ?? defaultGoal
            
            summaries.append(DailyIntakeSummary(
                date: current,
                totalMilliliters: total,
                dailyGoal: goalForDay
            ))
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return summaries
    }

    static func monthSummaries(
        for entries: [WaterIntakeEntry],
        goals: [DailyGoal],
        defaultGoal: Int,
        from startDate: Date,
        through endDate: Date,
        calendar: Calendar = .current
    ) -> [MonthIntakeSummary] {
        let dailySummaries = dailySummaries(for: entries, goals: goals, defaultGoal: defaultGoal, from: startDate, through: endDate, calendar: calendar)
        let groupedByMonth = Dictionary(grouping: dailySummaries) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? calendar.startOfDay(for: $0.date) }

        return groupedByMonth.map { monthStart, days in
            let total = days.reduce(0) { $0 + $1.totalMilliliters }
            let registeredDays = days.filter { $0.totalMilliliters > 0 }
            let average = registeredDays.isEmpty ? 0 : Int((Double(total) / Double(registeredDays.count)).rounded())
            return MonthIntakeSummary(monthStart: monthStart, totalMilliliters: total, averageDailyMilliliters: average)
        }
        .sorted { $0.monthStart < $1.monthStart }
    }

    static func yearSummaries(
        for entries: [WaterIntakeEntry],
        calendar: Calendar = .current
    ) -> [YearIntakeSummary] {
        guard let firstDate = entries.map(\.date).min() else { return [] }
        let start = calendar.dateInterval(of: .year, for: firstDate)?.start ?? calendar.startOfDay(for: firstDate)
        let end = calendar.startOfDay(for: .now)
        
        // Para las gráficas de año, no necesitamos los objetivos diarios uno a uno para la barra, 
        // pero si quisiéramos precisión total en el promedio deberíamos pasarlos. 
        // Por simplicidad y rendimiento, mantenemos la lógica de promedio sobre entradas registradas.
        let dailySummaries = dailySummaries(for: entries, goals: [], defaultGoal: IntakeConstants.defaultGoalMilliliters, from: start, through: end, calendar: calendar)
        
        let groupedByYear = Dictionary(grouping: dailySummaries) { calendar.dateInterval(of: .year, for: $0.date)?.start ?? calendar.startOfDay(for: $0.date) }

        return groupedByYear.map { yearStart, days in
            let total = days.reduce(0) { $0 + $1.totalMilliliters }
            let registeredDays = days.filter { $0.totalMilliliters > 0 }
            let average = registeredDays.isEmpty ? 0 : Int((Double(total) / Double(registeredDays.count)).rounded())
            return YearIntakeSummary(yearStart: yearStart, totalMilliliters: total, averageDailyMilliliters: average)
        }
        .sorted { $0.yearStart < $1.yearStart }
    }

    static func startDate(for period: StatisticsPeriod, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: .now)

        switch period {
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -6, to: today)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: today).map { calendar.date(byAdding: .day, value: 1, to: $0) ?? $0 }
        case .total:
            return nil
        }
    }

    static func reloadWidgetTimelineIfNeeded(for date: Date, calendar: Calendar = .current) {
        guard calendar.isDateInToday(date) else { return }
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }
	
	/// Cálculos para Insights

	static func calculateConsumptionTrend(from summaries: [DailyIntakeSummary]) -> TrendResult {
		let calendar = Calendar.current
		let now = Date()
		
		// Filtramos los últimos 7 días (incluyendo hoy)
		let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: now) ?? now
		let last7Days = summaries.filter { $0.date >= sevenDaysAgo }
		let avg7d = last7Days.isEmpty ? 0 : last7Days.reduce(0) { $0 + $1.totalMilliliters } / last7Days.count
		
		// Filtramos los últimos 30 días (incluyendo hoy)
		let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: now) ?? now
		let last30Days = summaries.filter { $0.date >= thirtyDaysAgo }
		let avg30d = last30Days.isEmpty ? 0 : last30Days.reduce(0) { $0 + $1.totalMilliliters } / last30Days.count
		
		let isImproving = avg7d > avg30d
		
		// Generamos el mensaje según tu propuesta
		let message: LocalizedStringResource
		if avg7d == 0 && avg30d == 0 {
			message = "Start logging to see trends"
		} else if isImproving {
			message = "Your hydration is on the rise 📈"
		} else {
			message = "Hydration is down compared to last month, keep it up! 📉"
		}
		
		return TrendResult(
			isImproving: isImproving,
			message: message,
			shortTermAverage: avg7d,
			longTermAverage: avg30d
		)
	}

	static func calculateWeeklyEvolution(from summaries: [DailyIntakeSummary]) -> WeeklyEvolutionResult {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		// 1. Obtener los últimos 7 días (incluyendo hoy)
		guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
			return WeeklyEvolutionResult(percentageChange: nil, currentWeekTotal: 0, previousWeekTotal: 0)
		}
		
		let currentWeekSummaries = summaries.filter { $0.date >= sevenDaysAgo && $0.date <= today }
		let currentWeekTotal = currentWeekSummaries.reduce(0) { $0 + $1.totalMilliliters }
		
		// 2. Obtener los 7 días anteriores (del día -13 al día -7)
		guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today),
			  let eightDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
			return WeeklyEvolutionResult(percentageChange: nil, currentWeekTotal: currentWeekTotal, previousWeekTotal: 0)
		}
		
		let previousWeekSummaries = summaries.filter { $0.date >= fourteenDaysAgo && $0.date < eightDaysAgo }
		let previousWeekTotal = previousWeekSummaries.reduce(0) { $0 + $1.totalMilliliters }
		
		// 3. Calcular porcentaje
		if previousWeekTotal == 0 {
			return WeeklyEvolutionResult(percentageChange: nil, currentWeekTotal: currentWeekTotal, previousWeekTotal: previousWeekTotal)
		}
		
		let change = (Double(currentWeekTotal - previousWeekTotal) / Double(previousWeekTotal))
		return WeeklyEvolutionResult(
			percentageChange: change,
			currentWeekTotal: currentWeekTotal,
			previousWeekTotal: previousWeekTotal
		)
	}
	
	static func calculateStability(from summaries: [DailyIntakeSummary], daysToAnalyze: AnalysisPeriod = .lastMonth) -> StabilityResult {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		// 1. Determinamos la fecha de inicio basándonos en el periodo real, NO en el índice del array
		let startDate: Date? = {
			switch daysToAnalyze {
			case .allTime: return nil
			case .lastWeek: return calendar.date(byAdding: .day, value: -6, to: today)
			case .lastMonth: return calendar.date(byAdding: .day, value: -29, to: today)
			case .lastYear: return calendar.date(byAdding: .day, value: -364, to: today)
			}
		}()
		
		// 2. Filtramos el array para obtener los días dentro de ese rango temporal exacto
		let recentSummaries: [DailyIntakeSummary]
		if let startDate {
			recentSummaries = summaries.filter { $0.date >= startDate }
		} else {
			recentSummaries = summaries
		}
		
		// Ahora 'counts' será el número real de días en ese periodo (ej: 7, 30, etc.)
		let counts = recentSummaries.count
		
		guard counts > 1 else {
			return StabilityResult(stabilityScore: 0, variabilityValue: 0, message: "Not enough data", isStable: false, averageDailyIntake: 0)
		}
		
		// 3. Los valores incluirán los ceros que 'dailySummaries' ya generó correctamente
		let values = recentSummaries.map { Double($0.totalMilliliters) }
		let mean = values.reduce(0, +) / Double(counts)
		
		// Calcular Desviación Estándar sobre el periodo completo (incluyendo ceros)
		let sumOfSquaredDifferences = values.map { pow($0 - mean, 2) }.reduce(0, +)
		let standardDeviation = sqrt(sumOfSquaredDifferences / Double(counts))
		
		// El coeficiente de variación (CV) mide la variabilidad relativa
		let coefficientOfVariation = mean > 0 ? (standardDeviation / mean) : 1.0
		
		// Si el CV es bajo, es estable.
		let stabilityScore = max(0, min(1, 1.0 - coefficientOfVariation))
		let isStable = coefficientOfVariation < 0.20
		
		let message: LocalizedStringResource
		if isStable {
			message = "Your hydration is very consistent! 🏆"
		} else if counts < (daysToAnalyze == .allTime ? Int.max : daysToAnalyze.rawValue) {
			// Si tenemos menos días de los que el periodo requiere, estamos recolectando
			message = "Analyzing your patterns..."
		} else {
			message = "Try to keep a more regular rhythm. ⚖️"
		}
		
		return StabilityResult(
			stabilityScore: stabilityScore,
			variabilityValue: Int(standardDeviation),
			message: message,
			isStable: isStable,
			averageDailyIntake: Int(mean)
		)
	}
	
	static func calculateSuccessRate(from summaries: [DailyIntakeSummary], daysToAnalyze: AnalysisPeriod = .lastMonth) -> SuccessRateResult {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		// 1. Determinamos la fecha de inicio según el periodo
		let startDate: Date? = {
			switch daysToAnalyze {
			case .allTime:
				return nil // No filtramos por fecha
			case .lastWeek:
				return calendar.date(byAdding: .day, value: -6, to: today)
			case .lastMonth:
				return calendar.date(byAdding: .day, value: -29, to: today)
			case .lastYear:
				return calendar.date(byAdding: .day, value: -364, to: today)
			}
		}()
		
		// 2. Filtramos el array basándonos en la fecha real del resumen
		let recentSummaries: [DailyIntakeSummary]
		if let startDate {
			// Solo incluimos días que sean iguales o posteriores a la fecha de inicio calculada
			recentSummaries = summaries.filter { $0.date >= startDate }
		} else {
			recentSummaries = summaries
		}
		
		let totalDays = recentSummaries.count
		
		guard totalDays > 0 else {
			return SuccessRateResult(rate: 0, daysMet: 0, totalDays: 0, message: "Start logging to see your success rate")
		}
		
		let daysMet = recentSummaries.filter { $0.reachedGoal }.count
		let rate = Double(daysMet) / Double(totalDays)
		
		// ... (resto de la lógica de mensajes se mantiene igual)
		let message: LocalizedStringResource
		if rate >= 0.9 {
			message = "You're a hydration champion! ⭐"
		} else if rate >= 0.7 {
			message = "Great consistency, keep it up! 👍"
		} else if rate > 0 {
			message = "Every day counts, stay hydrated! 💪"
		} else {
			message = "Ready to start your success streak? 💧"
		}
		
		return SuccessRateResult(
			rate: rate,
			daysMet: daysMet,
			totalDays: totalDays,
			message: message
		)
	}
	
	static func calculateRiskPrediction(from summaries: [DailyIntakeSummary], daysToAnalyze: AnalysisPeriod = .lastMonth) -> RiskPredictionResult {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		// 1. Determinamos la fecha de inicio basándonos en el periodo real, NO en el índice del array
		let startDate: Date? = {
			switch daysToAnalyze {
			case .allTime: return nil
			case .lastWeek: return calendar.date(byAdding: .day, value: -6, to: today)
			case .lastMonth: return calendar.date(byAdding: .day, value: -29, to: today)
			case .lastYear: return calendar.date(byAdding: .day, value: -364, to: today)
			}
		}()
		
		// 2. Filtramos el array para obtener los días dentro de ese rango temporal exacto
		let recentSummaries: [DailyIntakeSummary]
		if let startDate {
			recentSummaries = summaries.filter { $0.date >= startDate }
		} else {
			recentSummaries = summaries
		}
		
		guard recentSummaries.count >= 3 else {
			return RiskPredictionResult(riskLevel: .low, message: "Keep logging to build your pattern", confidenceScore: 0)
		}

		// 1. Analizar la racha actual (Streak)
		var currentStreak = 0
		for summary in recentSummaries {
			if summary.reachedGoal {
				currentStreak += 1
			} else {
				break
			}
		}

		// 2. Calcular frecuencia de cumplimiento histórica en este periodo
		let totalDaysInPeriod = recentSummaries.count
		let daysMet = recentSummaries.filter { $0.reachedGoal }.count
		let successRate = Double(daysMet) / Double(totalDaysInPeriod)

		// 3. Lógica de predicción de riesgo (MEJORADA)
		var risk: RiskLevel = .low
		var message: LocalizedStringResource = "You're doing great! Stay steady."
		
		if successRate < 0.3 && currentStreak == 0 {
			// CASO: Riesgo de abandono (sin racha y éxito muy bajo)
			risk = .high
			message = "It's hard to start, but every drop counts! 💧"
		} else if currentStreak >= 5 && successRate < 0.7 {
			// CASO: Riesgo de fatiga (racha alta pero éxito general bajo)
			risk = .medium
			message = "You've been strong lately! Don't let the momentum slip. 💪"
		} else if currentStreak > 0 && successRate < 0.5 {
			// CASO: Riesgo de ruptura (racha activa pero inestabilidad detectada)
			risk = .high
			message = "Warning: Your pattern is becoming unstable. Focus on today! ⚠️"
		} else if currentStreak >= 3 {
			// CASO: Racha positiva y estable
			risk = .low
			message = "You're building a solid habit. Keep it up! ✨"
		}

		return RiskPredictionResult(
			riskLevel: risk,
			message: message,
			confidenceScore: successRate // Usamos el rate como medida de confianza del patrón
		)
	}
}

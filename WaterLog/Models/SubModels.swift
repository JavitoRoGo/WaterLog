//
//  DailyIntakeSummary.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 03/08/2026.
//

import Foundation

struct DailyIntakeSummary: Identifiable, Hashable {
    let date: Date
    let totalMilliliters: Int
    let dailyGoal: Int // Añadido para saber contra qué comparar en cada día

    var id: Date { date }
    var measurement: Measurement<UnitVolume> { Measurement(value: Double(totalMilliliters), unit: .milliliters) }
    var progress: Double { IntakeAnalytics.progress(for: totalMilliliters, goal: dailyGoal) }
    var percentage: Int { IntakeAnalytics.percentage(for: totalMilliliters, goal: dailyGoal) }
    var reachedGoal: Bool { totalMilliliters >= dailyGoal }
}

struct MonthIntakeSummary: Identifiable, Hashable {
    let monthStart: Date
    let totalMilliliters: Int
    let averageDailyMilliliters: Int
	
	var id: Date { monthStart }
}

struct YearIntakeSummary: Identifiable, Hashable {
    let yearStart: Date
    let totalMilliliters: Int
    let averageDailyMilliliters: Int
	
	var id: Date { yearStart }
}

struct TrendResult {
	let isImproving: Bool
	let message: LocalizedStringResource
	let shortTermAverage: Int // 7d
	let longTermAverage: Int  // 30d
}

struct StatisticsChartData {
	let period: StatisticsPeriod
	let dailySummaries: [DailyIntakeSummary]
	let monthSummaries: [MonthIntakeSummary]
	let yearSummaries: [YearIntakeSummary]
	let intervalLabel: LocalizedStringResource
	let maximumValue: Int
	let visibleDomainLength: TimeInterval

	init(
		period: StatisticsPeriod,
		entries: [WaterIntakeEntry],
		goals: [DailyGoal],
		defaultGoal: Int,
		calendar: Calendar = .current
	) {
		self.period = period
		let today = calendar.startOfDay(for: .now)

		switch period {
		case .sevenDays:
			let start = IntakeAnalytics.startDate(for: .sevenDays, calendar: calendar) ?? today
			// Actualizado para usar la nueva firma de dailySummaries
			let daily = IntakeAnalytics.dailySummaries(
				for: entries,
				goals: goals,
				defaultGoal: defaultGoal,
				from: start,
				through: today,
				calendar: calendar
			)
			dailySummaries = daily
			monthSummaries = []
			yearSummaries = []
			intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
			let maxIngest = daily.map(\.totalMilliliters).max() ?? 0
			maximumValue = max(maxIngest, defaultGoal)
			visibleDomainLength = 60 * 60 * 24 * 7
			
		case .oneMonth:
			let start = IntakeAnalytics.startDate(for: .oneMonth, calendar: calendar) ?? today
			let daily = IntakeAnalytics.dailySummaries(
				for: entries,
				goals: goals,
				defaultGoal: defaultGoal,
				from: start,
				through: today,
				calendar: calendar
			)
			dailySummaries = daily
			monthSummaries = []
			yearSummaries = []
			intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
			let maxIngest = daily.map(\.totalMilliliters).max() ?? 0
			maximumValue = max(maxIngest, defaultGoal)
			visibleDomainLength = 60 * 60 * 24 * 31

		case .oneYear:
			let start = IntakeAnalytics.startDate(for: .oneYear, calendar: calendar) ?? today
			// Actualizado para usar la nueva firma de monthSummaries
			let months = IntakeAnalytics.monthSummaries(
				for: entries,
				goals: goals,
				defaultGoal: defaultGoal,
				from: start,
				through: today,
				calendar: calendar
			)
			dailySummaries = []
			monthSummaries = months
			yearSummaries = []
			intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
			maximumValue = months.map(\.averageDailyMilliliters).max() ?? defaultGoal
			visibleDomainLength = 60 * 60 * 24 * 31 * 12

		case .total:
			let years = IntakeAnalytics.yearSummaries(for: entries, calendar: calendar)
			dailySummaries = []
			monthSummaries = []
			yearSummaries = years
			let start = years.first?.yearStart ?? today
			intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
			maximumValue = years.map(\.averageDailyMilliliters).max() ?? defaultGoal
			visibleDomainLength = 60 * 60 * 24 * 365 * 5
		}
	}
	
	private static func intervalLabel(from startDate: Date, through endDate: Date) -> LocalizedStringResource {
		let start = WaterLogFormatters.shortDayAndMonth(startDate)
		let end = WaterLogFormatters.shortDayAndMonth(endDate)
		return "\(start) - \(end)"
	}
}

struct WeeklyEvolutionResult {
	let percentageChange: Double? // nil si no hay datos de la semana anterior para comparar
	let currentWeekTotal: Int
	let previousWeekTotal: Int
	
	var isPositive: Bool {
		(percentageChange ?? 0) >= 0
	}
}

struct StabilityResult {
	let stabilityScore: Double // 0.0 a 1.0 (donde 1 es perfecto)
	let variabilityValue: Int  // Desviación estándar en ml
	let message: LocalizedStringResource
	let isStable: Bool
	let averageDailyIntake: Int
	
	var title: LocalizedStringResource {
		isStable ? "Consistent Habit" : "Variable Pattern"
	}
}

struct SuccessRateResult {
	let rate: Double // 0.0 a 1.0
	let daysMet: Int
	let totalDays: Int
	let message: LocalizedStringResource
}

struct RiskPredictionResult {
	let riskLevel: RiskLevel
	let message: LocalizedStringResource
	let confidenceScore: Double // 0.0 a 1.0
}


/// El "Paquete de Contexto" que se enviará al LLM.
/// Es una representación semántica del estado de salud del usuario.
struct CoachingContext: Codable, Equatable {
	let summary: UserStatusSummary
	let metrics: DetailedMetrics
	let patterns: DetectedPatterns
	let timestamp: Date
	
	struct UserStatusSummary: Codable, Equatable {
		let overallRiskLevel: RiskLevel
		let primaryMotivationTag: MotivationTag // Para que el LLM sepa qué tono usar
	}
	
	struct DetailedMetrics: Codable, Equatable {
		let currentStreak: Int
		let successRate: Double
		let stabilityScore: Double
		let consumptionTrend: TrendDirection
		let weeklyEvolutionChange: Double? // Porcentaje de cambio vs semana pasada
	}
	
	struct DetectedPatterns: Codable, Equatable {
		let isImproving: Bool
		let isStable: Bool
		let hasHighVolatility: Bool
	}
	
	enum MotivationTag: String, Codable, CaseIterable {
		case celebratory   // "¡Lo estás haciendo genial!" -> Tono positivo/recompensa
		case encouraging   // "Vas por buen camino..." -> Tono motivador suave
		case urgent        // "¡Atención! Necesitas recuperar el ritmo" -> Tono de alerta/acción
		case neutral       // "Aquí tienes tus datos" -> Tono informativo
	}
	
	enum TrendDirection: String, Codable {
		case increasing, decreasing, stable, unknown
	}
}

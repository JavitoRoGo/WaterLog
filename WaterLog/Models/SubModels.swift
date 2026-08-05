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

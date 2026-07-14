//
//  StatisticsChartData.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 04/06/2026.
//

import SwiftUI

struct StatisticsChartData {
    let period: StatisticsPeriod
    let dailySummaries: [DailyIntakeSummary]
    let monthSummaries: [MonthIntakeSummary]
    let yearSummaries: [YearIntakeSummary]
    let intervalLabel: LocalizedStringResource
    let maximumValue: Int
    let visibleDomainLength: TimeInterval

    init(period: StatisticsPeriod, entries: [WaterIntakeEntry], calendar: Calendar = .current) {
        self.period = period
        let today = calendar.startOfDay(for: .now)

        switch period {
        case .sevenDays:
            let start = IntakeAnalytics.startDate(for: .sevenDays, calendar: calendar) ?? today
            let daily = IntakeAnalytics.dailySummaries(for: entries, from: start, through: today, calendar: calendar)
            dailySummaries = daily
            monthSummaries = []
            yearSummaries = []
            intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
            maximumValue = daily.map(\.totalMilliliters).max() ?? 0
            visibleDomainLength = 60 * 60 * 24 * 7
        case .oneYear:
            let start = IntakeAnalytics.startDate(for: .oneYear, calendar: calendar) ?? today
            let months = IntakeAnalytics.monthSummaries(for: entries, from: start, through: today, calendar: calendar)
            dailySummaries = []
            monthSummaries = months
            yearSummaries = []
            intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
            maximumValue = months.map(\.averageDailyMilliliters).max() ?? 0
            visibleDomainLength = 60 * 60 * 24 * 31 * 6
        case .total:
            let years = IntakeAnalytics.yearSummaries(for: entries, calendar: calendar)
            dailySummaries = []
            monthSummaries = []
            yearSummaries = years
            let start = years.first?.yearStart ?? today
            intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
            maximumValue = years.map(\.averageDailyMilliliters).max() ?? 0
            visibleDomainLength = 60 * 60 * 24 * 366 * 4
        }
    }

    private static func intervalLabel(from startDate: Date, through endDate: Date) -> LocalizedStringResource {
        let start = WaterLogFormatters.shortDayAndMonth(startDate)
        let end = WaterLogFormatters.shortDayAndMonth(endDate)
        return "\(start) - \(end)"
    }
}

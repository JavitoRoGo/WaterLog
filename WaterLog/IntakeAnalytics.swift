import Foundation

enum IntakeConstants {
    static let dailyGoalMilliliters = 2_000
    static let spanishLocale = Locale(identifier: "es_ES")
}

enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case sevenDays = "7 días"
    case fourWeeks = "4 semanas"
    case oneYear = "1 año"
    case total = "Total"

    var id: Self { self }
}

struct DailyIntakeSummary: Identifiable, Hashable {
    let date: Date
    let totalMilliliters: Int

    var id: Date { date }
    var measurement: Measurement<UnitVolume> { Measurement(value: Double(totalMilliliters), unit: .milliliters) }
    var progress: Double { IntakeAnalytics.progress(for: totalMilliliters) }
    var percentage: Int { IntakeAnalytics.percentage(for: totalMilliliters) }
    var reachedGoal: Bool { totalMilliliters >= IntakeConstants.dailyGoalMilliliters }
}

struct MonthIntakeSummary: Identifiable, Hashable {
    let monthStart: Date
    let totalMilliliters: Int
    let averageDailyMilliliters: Int

    var id: Date { monthStart }
    var reachedGoal: Bool { averageDailyMilliliters >= IntakeConstants.dailyGoalMilliliters }
}

struct YearIntakeSummary: Identifiable, Hashable {
    let yearStart: Date
    let totalMilliliters: Int
    let averageDailyMilliliters: Int

    var id: Date { yearStart }
    var reachedGoal: Bool { averageDailyMilliliters >= IntakeConstants.dailyGoalMilliliters }
}

enum IntakeAnalytics {
    static func progress(for totalMilliliters: Int) -> Double {
        min(Double(totalMilliliters) / Double(IntakeConstants.dailyGoalMilliliters), 1)
    }

    static func percentage(for totalMilliliters: Int) -> Int {
        Int((Double(totalMilliliters) / Double(IntakeConstants.dailyGoalMilliliters) * 100).rounded())
    }

    static func entries(_ entries: [WaterIntakeEntry], on day: Date, calendar: Calendar = .current) -> [WaterIntakeEntry] {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    static func totalMilliliters(_ entries: [WaterIntakeEntry], on day: Date, calendar: Calendar = .current) -> Int {
        self.entries(entries, on: day, calendar: calendar).reduce(0) { $0 + $1.amount }
    }

    static func dailySummaries(for entries: [WaterIntakeEntry], from startDate: Date, through endDate: Date, calendar: Calendar = .current) -> [DailyIntakeSummary] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let groupedTotals = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        var summaries: [DailyIntakeSummary] = []
        var current = start

        while current <= end {
            summaries.append(DailyIntakeSummary(date: current, totalMilliliters: groupedTotals[current, default: 0]))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return summaries
    }

    static func monthSummaries(for entries: [WaterIntakeEntry], from startDate: Date, through endDate: Date, calendar: Calendar = .current) -> [MonthIntakeSummary] {
        let dailySummaries = dailySummaries(for: entries, from: startDate, through: endDate, calendar: calendar)
        let groupedByMonth = Dictionary(grouping: dailySummaries) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? calendar.startOfDay(for: $0.date) }

        return groupedByMonth.map { monthStart, days in
            let total = days.reduce(0) { $0 + $1.totalMilliliters }
            let registeredDays = days.filter { $0.totalMilliliters > 0 }
            let average = registeredDays.isEmpty ? 0 : Int((Double(total) / Double(registeredDays.count)).rounded())
            return MonthIntakeSummary(monthStart: monthStart, totalMilliliters: total, averageDailyMilliliters: average)
        }
        .sorted { $0.monthStart < $1.monthStart }
    }

    static func yearSummaries(for entries: [WaterIntakeEntry], calendar: Calendar = .current) -> [YearIntakeSummary] {
        guard let firstDate = entries.map(\.date).min() else { return [] }
        let start = calendar.dateInterval(of: .year, for: firstDate)?.start ?? calendar.startOfDay(for: firstDate)
        let end = calendar.startOfDay(for: .now)
        let dailySummaries = dailySummaries(for: entries, from: start, through: end, calendar: calendar)
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
        case .fourWeeks:
            return calendar.date(byAdding: .day, value: -27, to: today)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: today).map { calendar.date(byAdding: .day, value: 1, to: $0) ?? $0 }
        case .total:
            return nil
        }
    }
}

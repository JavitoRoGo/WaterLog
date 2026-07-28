import Foundation
import WidgetKit

enum IntakeConstants {
    // Este valor se usará solo como respaldo extremo si no hay nada en AppStorage, 
    // pero la lógica principal vendrá de los parámetros de las funciones.
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
    // El "reachedGoal" a nivel mensual es ambiguo con objetivos variables, 
    // pero lo mantendremos comparando contra el promedio o un valor base si fuera necesario.
    // Por ahora, usaremos el objetivo por defecto para la métrica visual de la gráfica mensual.
    var reachedGoal: Bool { averageDailyMilliliters >= IntakeConstants.defaultGoalMilliliters }
	
	var id: Date { monthStart }
}

struct YearIntakeSummary: Identifiable, Hashable {
    let yearStart: Date
    let totalMilliliters: Int
    let averageDailyMilliliters: Int
    var reachedGoal: Bool { averageDailyMilliliters >= IntakeConstants.defaultGoalMilliliters }
	
	var id: Date { yearStart }
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
}

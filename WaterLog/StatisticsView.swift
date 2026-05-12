import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
    @State private var selectedPeriod: StatisticsPeriod = .sevenDays
    @State private var selectedDay: DailyIntakeSummary?
    @State private var selectedMonth: MonthIntakeSummary?
    @State private var selectedYear: YearIntakeSummary?

    private var chartData: StatisticsChartData {
        StatisticsChartData(period: selectedPeriod, entries: entries)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Periodo", selection: $selectedPeriod) {
                    ForEach(StatisticsPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Label(chartData.intervalLabel, systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                IntakeChartView(data: chartData)
                    .frame(height: 240)
                    .padding(.horizontal)

                periodList
            }
            .navigationTitle("Historial")
        }
        .sheet(item: $selectedDay) { summary in
            NavigationStack {
                DayDetailView(date: summary.date)
            }
        }
        .sheet(item: $selectedMonth) { summary in
            NavigationStack {
                MonthDetailView(month: summary, entries: entries)
            }
        }
        .sheet(item: $selectedYear) { summary in
            YearDetailView(year: summary, entries: entries)
        }
    }

    @ViewBuilder
    private var periodList: some View {
        switch selectedPeriod {
        case .sevenDays, .fourWeeks:
            List(chartData.dailySummaries.reversed()) { summary in
                Button {
                    selectedDay = summary
                } label: {
                    DailySummaryRow(summary: summary)
                }
                .buttonStyle(.plain)
            }
        case .oneYear:
            List(chartData.monthSummaries.reversed()) { summary in
                Button {
                    selectedMonth = summary
                } label: {
                    MonthSummaryRow(summary: summary)
                }
                .buttonStyle(.plain)
            }
        case .total:
            List(chartData.yearSummaries.reversed()) { summary in
                Button {
                    selectedYear = summary
                } label: {
                    YearSummaryRow(summary: summary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct IntakeChartView: View {
    let data: StatisticsChartData

    var body: some View {
        Chart {
            switch data.period {
            case .sevenDays, .fourWeeks:
                ForEach(data.dailySummaries) { summary in
                    BarMark(
                        x: .value("Fecha", summary.date, unit: .day),
                        y: .value("Mililitros", summary.totalMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            case .oneYear:
                ForEach(data.monthSummaries) { summary in
                    BarMark(
                        x: .value("Mes", summary.monthStart, unit: .month),
                        y: .value("Media diaria", summary.averageDailyMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            case .total:
                ForEach(data.yearSummaries) { summary in
                    BarMark(
                        x: .value("Año", summary.yearStart, unit: .year),
                        y: .value("Media diaria", summary.averageDailyMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXAxis {
            switch data.period {
            case .sevenDays, .fourWeeks:
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(IntakeConstants.spanishLocale))
                }
            case .oneYear:
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).locale(IntakeConstants.spanishLocale))
                }
            case .total:
                AxisMarks(values: .stride(by: .year)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.year().locale(IntakeConstants.spanishLocale))
                }
            }
        }
        .chartYScale(domain: 0...max(data.maximumValue, IntakeConstants.dailyGoalMilliliters))
        .chartXVisibleDomain(length: data.visibleDomainLength)
    }
}

struct StatisticsChartData {
    let period: StatisticsPeriod
    let dailySummaries: [DailyIntakeSummary]
    let monthSummaries: [MonthIntakeSummary]
    let yearSummaries: [YearIntakeSummary]
    let intervalLabel: String
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
        case .fourWeeks:
            let start = IntakeAnalytics.startDate(for: .fourWeeks, calendar: calendar) ?? today
            let daily = IntakeAnalytics.dailySummaries(for: entries, from: start, through: today, calendar: calendar)
            dailySummaries = daily
            monthSummaries = []
            yearSummaries = []
            intervalLabel = StatisticsChartData.intervalLabel(from: start, through: today)
            maximumValue = daily.map(\.totalMilliliters).max() ?? 0
            visibleDomainLength = 60 * 60 * 24 * 14
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

    private static func intervalLabel(from startDate: Date, through endDate: Date) -> String {
        "\(WaterLogFormatters.shortDayAndMonth(startDate)) - \(WaterLogFormatters.shortDayAndMonth(endDate))"
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

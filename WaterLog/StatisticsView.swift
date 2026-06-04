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

#Preview {
    StatisticsView()
        .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

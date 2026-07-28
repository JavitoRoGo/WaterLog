import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
	@Query(sort: \DailyGoal.date, order: .forward) private var goals: [DailyGoal] // Añadido para obtener objetivos
	
	@AppStorage(WaterLogStore.keyForStandardGoalMilliliters, store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)) private var standardGoal: Int = IntakeConstants.defaultGoalMilliliters

    @State private var selectedPeriod: StatisticsPeriod = .sevenDays
    @State private var selectedDay: DailyIntakeSummary?
    @State private var selectedMonth: MonthIntakeSummary?
    @State private var selectedYear: YearIntakeSummary?

	// Actualizado para pasar los nuevos parámetros necesarios a StatisticsChartData
	private var chartData: StatisticsChartData {
		StatisticsChartData(
			period: selectedPeriod,
			entries: entries,
			goals: goals,
			defaultGoal: standardGoal
		)
	}

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatisticsPeriod.allCases) { period in
                        Text(period.title).tag(period)
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
            .navigationTitle("Historical")
        }
        .sheet(item: $selectedDay) { summary in
            NavigationStack {
                DayDetailView(date: summary.date)
            }
        }
        .sheet(item: $selectedMonth) { summary in
            NavigationStack {
				MonthDetailView(month: summary, entries: entries, goals: goals, defaultGoal: standardGoal)
            }
        }
        .sheet(item: $selectedYear) { summary in
			YearDetailView(year: summary, entries: entries, goals: goals, defaultGoal: standardGoal)
        }
    }

    @ViewBuilder
    private var periodList: some View {
        switch selectedPeriod {
        case .sevenDays:
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

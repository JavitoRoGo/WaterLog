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
				
				PeriodList(chartData: chartData, selectedPeriod: $selectedPeriod, selectedDay: $selectedDay, selectedMonth: $selectedMonth, selectedYear: $selectedYear)
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
}

#Preview {
    StatisticsView()
        .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

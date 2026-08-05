//
//  PeriodList.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct PeriodList: View {
	let chartData: StatisticsChartData
	
	@Binding var selectedPeriod: StatisticsPeriod
	@Binding var selectedDay: DailyIntakeSummary?
	@Binding var selectedMonth: MonthIntakeSummary?
	@Binding var selectedYear: YearIntakeSummary?
	
	var body: some View {
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
	PeriodList(chartData: .init(period: .sevenDays, entries: [], goals: [], defaultGoal: 2000), selectedPeriod: .constant(.oneYear), selectedDay: .constant(nil), selectedMonth: .constant(nil), selectedYear: .constant(nil))
}

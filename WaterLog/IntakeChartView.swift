//
//  IntakeChartView.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 04/06/2026.
//

import SwiftUI
import Charts

struct IntakeChartView: View {
    let data: StatisticsChartData

    var body: some View {
        Chart {
            switch data.period {
            case .sevenDays:
                ForEach(data.dailySummaries) { summary in
                    BarMark(
                        x: .value(String(localized: "Date"), summary.date, unit: .day),
                        y: .value(String(localized: "Volume"), summary.totalMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            case .oneYear:
                ForEach(data.monthSummaries) { summary in
                    BarMark(
                        x: .value(String(localized: "Month"), summary.monthStart, unit: .month),
                        y: .value(String(localized: "Daily average"), summary.averageDailyMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            case .total:
                ForEach(data.yearSummaries) { summary in
                    BarMark(
                        x: .value(String(localized: "Year"), summary.yearStart, unit: .year),
                        y: .value(String(localized: "Daily average"), summary.averageDailyMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                }
            }
        }
//        .chartScrollableAxes(.horizontal)
        .chartXAxis {
            switch data.period {
            case .sevenDays:
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(IntakeConstants.appLocale))
                }
            case .oneYear:
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).locale(IntakeConstants.appLocale))
                }
            case .total:
                AxisMarks(values: .stride(by: .year)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.year().locale(IntakeConstants.appLocale))
                }
            }
        }
		.chartYAxis {
			AxisMarks() { value in
				AxisValueLabel() {
					if let intValue = value.as(Int.self) {
						Text(WaterLogFormatters.volumeFromMilliliters(intValue))
					}
				}
			}
		}
        .chartYScale(domain: 0...max(data.maximumValue, IntakeConstants.dailyGoalMilliliters))
        .chartXVisibleDomain(length: data.visibleDomainLength)
    }
}

#Preview {
	IntakeChartView(data: StatisticsChartData(period: .oneYear, entries: []))
}

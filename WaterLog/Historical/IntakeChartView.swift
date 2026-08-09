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
			case .sevenDays, .oneMonth:
                ForEach(data.dailySummaries) { summary in
                    // Barra de ingesta
                    BarMark(
                        x: .value(String(localized: "Date"), summary.date, unit: .day),
                        y: .value(String(localized: "Volume"), summary.totalMilliliters)
                    )
                    .foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
                    
                    let startOfDay = Calendar.current.startOfDay(for: summary.date)
                    let midOfDay = Calendar.current.date(byAdding: .hour, value: 12, to: startOfDay)!

//                    LineMark(
//                        x: .value("End", midOfDay, unit: .second),
//                        y: .value("Goal", summary.dailyGoal)
//                    )
//                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
//                    .foregroundStyle(.red.opacity(0.3))
					
					PointMark(
						x: .value("Date", midOfDay, unit: .second),
						y: .value("Daily Goal", summary.dailyGoal)
					)
					.symbol(.diamond)
					.foregroundStyle(.orange)
//					.annotation(position: .top) {
//						Text("\(summary.dailyGoal)ml")
//							.font(.caption2)
//							.foregroundStyle(.secondary)
//					}
                }
            case .oneYear:
                ForEach(data.monthSummaries) { summary in
                    BarMark(
                        x: .value(String(localized: "Month"), summary.monthStart, unit: .month),
                        y: .value(String(localized: "Daily average"), summary.averageDailyMilliliters)
					)
					.foregroundStyle(.blue.gradient)
                }
            case .total:
                ForEach(data.yearSummaries) { summary in
                    BarMark(
                        x: .value(String(localized: "Year"), summary.yearStart, unit: .year),
                        y: .value(String(localized: "Daily average"), summary.averageDailyMilliliters)
                    )
					.foregroundStyle(.blue.gradient)
                }
            }
        }
        .chartXAxis {
            switch data.period {
            case .sevenDays:
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(IntakeConstants.appLocale))
                }
			case .oneMonth:
				AxisMarks(values: .stride(by: .day, count: 5)) { value in
					AxisGridLine()
					AxisTick()
					AxisValueLabel(format: .dateTime.day().month(.defaultDigits).locale(IntakeConstants.appLocale))
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
        .chartYScale(domain: 0...max(data.maximumValue, IntakeConstants.defaultGoalMilliliters))
        .chartXVisibleDomain(length: data.visibleDomainLength)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!
    
    // Datos de entrada (consumo de agua)
    let entries = [
        WaterIntakeEntry(date: today, amount: 1250),
        WaterIntakeEntry(date: yesterday, amount: 500),
        WaterIntakeEntry(date: dayBeforeYesterday, amount: 3000)
    ]
    
    // Objetivos diarios (DailyGoal)
    let goals = [
        DailyGoal(date: today, amount: 1500),
        DailyGoal(date: yesterday, amount: 1000), // Objetivo alto para ver la diferencia
        DailyGoal(date: dayBeforeYesterday, amount: 2500)
    ]
    
    return IntakeChartView(data: StatisticsChartData(
        period: .sevenDays,
        entries: entries,
        goals: goals,
        defaultGoal: 2000
    ))
}

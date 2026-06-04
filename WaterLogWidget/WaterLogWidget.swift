//
//  WaterLogWidget.swift
//  WaterLogWidget
//
//  Created by Javier Rodríguez Gómez on 14/05/2026.
//

import WidgetKit
import SwiftUI
import AppIntents
import SwiftData
import Charts

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WaterLogWidgetEntry {
        WaterLogWidgetEntry(date: .now, totalWater: 0, weeklyEntries: [], showSuccess: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterLogWidgetEntry) -> Void) {
		let entries = fetchWeeklyEntries()
        let entry = WaterLogWidgetEntry(
            date: .now,
            totalWater: fetchTodayTotal(for: entries),
            weeklyEntries: fetchWeeklySummaries(for: entries),
            showSuccess: false
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
        let lastSuccess = defaults?.object(forKey: WaterLogStore.keyForLastSuccessDate) as? Date
		let weeklyEntries = fetchWeeklyEntries()
        let todayTotal = fetchTodayTotal(for: weeklyEntries)
        let weeklySummaries = fetchWeeklySummaries(for: weeklyEntries)
        let nextDay = nextDayBoundary()
        
        // Si el último éxito ocurrió hace menos de 1.5 segundos, creamos la secuencia de feedback.
        if let lastSuccess, abs(lastSuccess.timeIntervalSince(.now)) < 1.5 {
            let successEntry = WaterLogWidgetEntry(date: lastSuccess, totalWater: todayTotal, weeklyEntries: weeklySummaries, showSuccess: true)
            let normalEntry = WaterLogWidgetEntry(date: lastSuccess.addingTimeInterval(1), totalWater: todayTotal, weeklyEntries: weeklySummaries, showSuccess: false)
            
            let timeline = Timeline(entries: [successEntry, normalEntry], policy: .after(nextDay))
            completion(timeline)
        } else {
            // Estado normal: programamos una recarga para recalcular el total al cambiar de día.
            let entry = WaterLogWidgetEntry(date: .now, totalWater: todayTotal, weeklyEntries: weeklySummaries, showSuccess: false)
            let timeline = Timeline(entries: [entry], policy: .after(nextDay))
            completion(timeline)
        }
    }
    
    private func nextDayBoundary(calendar: Calendar = .current) -> Date {
        calendar.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(60 * 60)
    }
	
	private func fetchWeeklyEntries() -> [WaterIntakeEntry] {
		do {
			let container = try WaterLogStore.makeModelContainer()
			let context = ModelContext(container)
			
			let calendar = Calendar.current
			let startOfToday = calendar.startOfDay(for: .now)
			// Calculamos el inicio de la semana (hace 6 días para tener 7 días en total incluyendo hoy)
			let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

			let fetchDescriptor = FetchDescriptor<WaterIntakeEntry>(
				predicate: #Predicate<WaterIntakeEntry> { $0.date >= startDate }
			)
			
			return try context.fetch(fetchDescriptor)
		} catch {
			print("Error fetching today's total for widget: \(error)")
			return []
		}
	}
    
    private func fetchTodayTotal(for entries: [WaterIntakeEntry]) -> Int {
		let startOfDay = Calendar.current.startOfDay(for: .now)
		let todayEntries = entries.filter { $0.date >= startOfDay }
		let todayTotal = todayEntries.reduce(0) { $0 + $1.amount }
		return todayTotal
    }

	private func fetchWeeklySummaries(for entries: [WaterIntakeEntry]) -> [DailyIntakeSummary] {
		let calendar = Calendar.current
		let startOfToday = calendar.startOfDay(for: .now)
		// Calculamos el inicio de la semana (hace 6 días para tener 7 días en total incluyendo hoy)
		let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

		return IntakeAnalytics.dailySummaries(for: entries, from: startDate, through: startOfToday, calendar: calendar)
	}
}

struct WaterLogWidgetEntry: TimelineEntry {
    let date: Date
    let totalWater: Int
    let weeklyEntries: [DailyIntakeSummary]
    let showSuccess: Bool
}

struct WaterLogWidgetEntryView: View {
	@Environment(\.widgetFamily) private var family
    var entry: Provider.Entry
	
	var body: some View {
		VStack {
			HStack(spacing: 20) {
				VStack {
					Label("WaterLog", systemImage: "drop.fill")
						.font(.headline)
						.foregroundStyle(.blue)
						.padding(.bottom, 8)
					
					if entry.showSuccess {
						// Feedback visual de éxito
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: family != .systemLarge ? 40 : 80))
							.foregroundStyle(.green)
							.frame(maxHeight: .infinity, alignment: .center)
							.transition(.scale.combined(with: .opacity))
					} else {
						Text("Añadir ahora")
							.font(.caption)
							.foregroundStyle(.secondary)
						
						WaterAmountButtons()
					}
				}
				
				if family == .systemMedium || family == .systemLarge {
					ProgressRingView(
						totalMilliliters: entry.totalWater,
						goalMilliliters: IntakeConstants.dailyGoalMilliliters,
						lineWidth: 10,
						font: .title3
					)
				}
			}
			
			if family == .systemLarge {
				Chart {
					ForEach(entry.weeklyEntries) { summary in
						BarMark(
							x: .value("Fecha", summary.date, unit: .day),
							y: .value("Mililitros", summary.totalMilliliters)
						)
						.foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
					}
				}
				.chartXAxis {
					AxisMarks(values: .stride(by: .day)) { value in
						AxisGridLine()
						AxisTick()
						AxisValueLabel(
							format: .dateTime.weekday().locale(
								IntakeConstants.spanishLocale
							),
							centered: true
						)
					}
				}
				.padding(.top, 10)
			}
		}
	}
}

private struct WaterAmountButtons: View {
	var body: some View {
		VStack {
			WaterAmountButton(amount: 125)
			WaterAmountButton(amount: 250)
			WaterAmountButton(amount: 500)
		}
	}
}

private struct WaterAmountButton: View {
    let amount: Int

    var body: some View {
        Button(intent: AddWaterIntakeIntent(amount: amount)) {
            Text("\(amount) ml")
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.mini)
    }
}

struct WaterLogWidget: Widget {
    let kind: String = "WaterLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WaterLogWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WaterLogWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("WaterLog")
        .description("Añade agua rápidamente sin abrir la app.")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

#Preview(as: .systemSmall) {
    WaterLogWidget()
} timeline: {
    WaterLogWidgetEntry(date: .now, totalWater: 500, weeklyEntries: [], showSuccess: false)
    WaterLogWidgetEntry(date: .now, totalWater: 1200, weeklyEntries: [], showSuccess: true)
}

#Preview(as: .systemMedium) {
    WaterLogWidget()
} timeline: {
    WaterLogWidgetEntry(date: .now, totalWater: 500, weeklyEntries: [], showSuccess: false)
    WaterLogWidgetEntry(date: .now, totalWater: 1200, weeklyEntries: [], showSuccess: true)
}

#Preview(as: .systemLarge) {
    WaterLogWidget()
} timeline: {
	WaterLogWidgetEntry(date: .now, totalWater: 500, weeklyEntries: [.init(date: .now, totalMilliliters: 500), .init(date: .now.addingTimeInterval(-86400), totalMilliliters: 3200)], showSuccess: false)
	WaterLogWidgetEntry(date: .now, totalWater: 1200, weeklyEntries: [.init(date: .now, totalMilliliters: 1200), .init(date: .now.addingTimeInterval(-86400), totalMilliliters: 3200)], showSuccess: true)
}

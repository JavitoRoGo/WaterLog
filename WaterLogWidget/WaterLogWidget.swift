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
		let (entries, goals, defaultGoal) = fetchData()
        let entry = WaterLogWidgetEntry(
            date: .now,
            totalWater: fetchTodayTotal(for: entries),
            weeklyEntries: fetchWeeklySummaries(for: entries, goals: goals, defaultGoal: defaultGoal),
            showSuccess: false
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
        let lastSuccess = defaults?.object(forKey: WaterLogStore.keyForLastSuccessDate) as? Date
		
        let (weeklyEntries, goals, defaultGoal) = fetchData()
        let todayTotal = fetchTodayTotal(for: weeklyEntries)
        let weeklySummaries = fetchWeeklySummaries(for: weeklyEntries, goals: goals, defaultGoal: defaultGoal)
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

    // Helper para centralizar la obtención de datos necesarios del contenedor compartido
    private func fetchData() -> (entries: [WaterIntakeEntry], goals: [DailyGoal], defaultGoal: Int) {
        do {
            let container = try WaterLogStore.makeModelContainer()
            let context = ModelContext(container)
            
            // 1. Obtener Entradas
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: .now)
            let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
            let entryFetch = FetchDescriptor<WaterIntakeEntry>(predicate: #Predicate<WaterIntakeEntry> { $0.date >= startDate })
            let entries = try context.fetch(entryFetch)

            // 2. Obtener Objetivos
            let goalFetch = FetchDescriptor<DailyGoal>()
            let goals = try context.fetch(goalFetch)

            // 3. Obtener Objetivo por Defecto (de AppStorage en el grupo)
            let appGroupDefaults = UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
            let defaultGoal = appGroupDefaults?.integer(forKey: "standardGoalMilliliters") ?? IntakeConstants.defaultGoalMilliliters

            return (entries, goals, defaultGoal)
        } catch {
            print("Error fetching data for widget: \(error)")
            return ([], [], IntakeConstants.defaultGoalMilliliters)
        }
    }
	
	private func fetchTodayTotal(for entries: [WaterIntakeEntry]) -> Int {
		let startOfDay = Calendar.current.startOfDay(for: .now)
		let todayEntries = entries.filter { $0.date >= startOfDay }
		return todayEntries.reduce(0) { $0 + $1.amount }
    }

	private func fetchWeeklySummaries(for entries: [WaterIntakeEntry], goals: [DailyGoal], defaultGoal: Int) -> [DailyIntakeSummary] {
		let calendar = Calendar.current
		let startOfToday = calendar.startOfDay(for: .now)
		let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

		return IntakeAnalytics.dailySummaries(
            for: entries, 
            goals: goals, 
            defaultGoal: defaultGoal, 
            from: startDate, 
            through: startOfToday, 
            calendar: calendar
        )
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
						Text("Add now")
							.font(.caption)
							.foregroundStyle(.secondary)
						
						WaterAmountButtons()
					}
				}
				
				if family == .systemMedium || family == .systemLarge {
					// Usamos el objetivo del último día registrado en la entrada del widget para que sea dinámico
					let goal = entry.weeklyEntries.last?.dailyGoal ?? IntakeConstants.defaultGoalMilliliters
					ProgressRingView(
						totalMilliliters: entry.totalWater,
						goalMilliliters: goal,
						lineWidth: 10,
						font: .title3
					)
				}
			}
			
			if family == .systemLarge {
				Chart {
					ForEach(entry.weeklyEntries) { summary in
						BarMark(
							x: .value(String(localized: "Date"), summary.date, unit: .day),
							y: .value(String(localized: "Volume"), summary.totalMilliliters)
						)
						.foregroundStyle(summary.reachedGoal ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.blue.gradient))
						PointMark(
							x: .value(String(localized: "Date"), summary.date, unit: .day),
							y: .value(String(localized: "Daily Goal"), summary.dailyGoal)
						)
						.symbol(.diamond)
						.foregroundStyle(.orange)
					}
				}
				.chartXAxis {
					AxisMarks(values: .stride(by: .day)) { value in
						AxisGridLine()
						AxisTick()
						AxisValueLabel(
							format: .dateTime.weekday().locale(
								IntakeConstants.appLocale
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
	// Usamos UserDefaults con el App Group para leer los mismos valores que la App
	@AppStorage("buttonAmount1", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount1: Int = 125
	@AppStorage("buttonAmount2", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount2: Int = 250
	@AppStorage("buttonAmount3", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount3: Int = 500

	var body: some View {
		VStack {
			WaterAmountButton(amount: amount1)
			WaterAmountButton(amount: amount2)
			WaterAmountButton(amount: amount3)
		}
	}
}

private struct WaterAmountButton: View {
    let amount: Int

    var body: some View {
        Button(intent: AddWaterIntakeIntent(amount: amount)) {
            Text(WaterLogFormatters.volumeFromMilliliters(amount))
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
        .description("Add water intake with a quick tap.")
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
	WaterLogWidgetEntry(date: .now, totalWater: 500, weeklyEntries: [.init(date: .now, totalMilliliters: 500, dailyGoal: 1500), .init(date: .now.addingTimeInterval(-86400), totalMilliliters: 3200, dailyGoal: 2000)], showSuccess: false)
	WaterLogWidgetEntry(date: .now, totalWater: 1200, weeklyEntries: [.init(date: .now, totalMilliliters: 1200, dailyGoal: 1500), .init(date: .now.addingTimeInterval(-86400), totalMilliliters: 3200, dailyGoal: 2000)], showSuccess: true)
}

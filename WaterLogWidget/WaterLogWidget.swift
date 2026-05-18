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

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WaterLogWidgetEntry {
        WaterLogWidgetEntry(date: .now, totalWater: 0, showSuccess: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterLogWidgetEntry) -> Void) {
        let entry = WaterLogWidgetEntry(date: .now, totalWater: fetchTodayTotal(), showSuccess: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
        let lastSuccess = defaults?.object(forKey: WaterLogStore.keyForLastSuccessDate) as? Date
        let todayTotal = fetchTodayTotal()
        let nextDay = nextDayBoundary()
        
        // Si el último éxito ocurrió hace menos de 1.5 segundos, creamos la secuencia de feedback.
        if let lastSuccess, abs(lastSuccess.timeIntervalSince(.now)) < 1.5 {
            let successEntry = WaterLogWidgetEntry(date: lastSuccess, totalWater: todayTotal, showSuccess: true)
            let normalEntry = WaterLogWidgetEntry(date: lastSuccess.addingTimeInterval(1), totalWater: todayTotal, showSuccess: false)
            
            let timeline = Timeline(entries: [successEntry, normalEntry], policy: .after(nextDay))
            completion(timeline)
        } else {
            // Estado normal: programamos una recarga para recalcular el total al cambiar de día.
            let entry = WaterLogWidgetEntry(date: .now, totalWater: todayTotal, showSuccess: false)
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
    
    private func fetchTodayTotal() -> Int {
        do {
            let container = try WaterLogStore.makeModelContainer()
            let context = ModelContext(container)
            
            let startOfDay = Calendar.current.startOfDay(for: .now)
            let fetchDescriptor = FetchDescriptor<WaterIntakeEntry>(
                predicate: #Predicate<WaterIntakeEntry> { $0.date >= startOfDay }
            )
            
            let entries = try context.fetch(fetchDescriptor)
            return entries.reduce(0) { $0 + $1.amount }
        } catch {
            print("Error fetching today's total for widget: \(error)")
            return 0
        }
    }
}

struct WaterLogWidgetEntry: TimelineEntry {
    let date: Date
    let totalWater: Int
    let showSuccess: Bool
}

struct WaterLogWidgetEntryView: View {
	@Environment(\.widgetFamily) private var family
    var entry: Provider.Entry
	
	var body: some View {
		HStack(spacing: 20) {
			VStack {
				Label("WaterLog", systemImage: "drop.fill")
					.font(.headline)
					.foregroundStyle(.blue)
				
				Spacer()
				
				if entry.showSuccess {
					// Feedback visual de éxito
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 40))
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
			
			if family == .systemMedium {
				ProgressRingView(
                    totalMilliliters: entry.totalWater,
                    goalMilliliters: IntakeConstants.dailyGoalMilliliters,
                    lineWidth: 10,
                    font: .title3
                )
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
		.supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WaterLogWidget()
} timeline: {
    WaterLogWidgetEntry(date: .now, totalWater: 500, showSuccess: false)
    WaterLogWidgetEntry(date: .now, totalWater: 1200, showSuccess: true)
}

#Preview(as: .systemMedium) {
    WaterLogWidget()
} timeline: {
    WaterLogWidgetEntry(date: .now, totalWater: 500, showSuccess: false)
    WaterLogWidgetEntry(date: .now, totalWater: 1200, showSuccess: true)
}

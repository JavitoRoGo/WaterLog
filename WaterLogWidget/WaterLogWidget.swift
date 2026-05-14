//
//  WaterLogWidget.swift
//  WaterLogWidget
//
//  Created by Javier Rodríguez Gómez on 14/05/2026.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WaterLogWidgetEntry {
        WaterLogWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterLogWidgetEntry) -> Void) {
        let entry = WaterLogWidgetEntry(date: .now)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogWidgetEntry>) -> Void) {
        let entry = WaterLogWidgetEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct WaterLogWidgetEntry: TimelineEntry {
    let date: Date
}

struct WaterLogWidgetEntryView: View {
    var entry: Provider.Entry
	
	var body: some View {
		VStack {
			Label("WaterLog", systemImage: "drop.fill")
				.font(.headline)
				.foregroundStyle(.blue)
			
			Spacer()
			
			Text("Añadir ahora")
				.font(.caption)
				.foregroundStyle(.secondary)
			
			WaterAmountButtons()
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
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    WaterLogWidget()
} timeline: {
    WaterLogWidgetEntry(date: .now)
}

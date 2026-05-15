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
        WaterLogWidgetEntry(date: .now, showSuccess: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterLogWidgetEntry) -> Void) {
        let entry = WaterLogWidgetEntry(date: .now, showSuccess: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)
		let lastSuccess = defaults?.object(forKey: WaterLogStore.keyForLastSuccessDate) as? Date
        
        // Si el último éxito ocurrió hace menos de 1.5 segundos, creamos la secuencia de feedback
        if let lastSuccess, abs(lastSuccess.timeIntervalSince(.now)) < 1.5 {
            let successEntry = WaterLogWidgetEntry(date: lastSuccess, showSuccess: true)
            let normalEntry = WaterLogWidgetEntry(date: lastSuccess.addingTimeInterval(1), showSuccess: false)
            
            // Creamos una línea de tiempo con ambas entradas. 
            // Al terminar la 'normalEntry', el sistema volverá a pedir un timeline según la política.
            let timeline = Timeline(entries: [successEntry, normalEntry], policy: .atEnd)
            completion(timeline)
        } else {
            // Estado normal: sin feedback de éxito activo.
            let entry = WaterLogWidgetEntry(date: .now, showSuccess: false)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}

struct WaterLogWidgetEntry: TimelineEntry {
    let date: Date
    let showSuccess: Bool
}

struct WaterLogWidgetEntryView: View {
    var entry: Provider.Entry
	
	var body: some View {
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
    WaterLogWidgetEntry(date: .now, showSuccess: false)
    WaterLogWidgetEntry(date: .now, showSuccess: true)
}


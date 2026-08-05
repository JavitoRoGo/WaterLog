//
//  LongestStreakSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct LongestStreakSection: View {
	let streakInfo: StreakResults
	let maxRecord: DailyIntakeSummary?
	let maxMonthly: MonthlyRecord?
	
	init(summaries: [DailyIntakeSummary]) {
		self.streakInfo = Streaks.calculateStreaks(from: summaries)
		self.maxRecord = Streaks.calculateExtremeRecords(from: summaries)
		self.maxMonthly = Streaks.calculateMaxMonthlyIntake(from: summaries)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// --- SUBSECCIÓN: MEJOR RACHA ---
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					Image(systemName: "trophy.fill")
						.foregroundStyle(.orange)
					Text("Best streak: \(streakInfo.longestStreak) days")
						.font(.headline)
				}
				
				if let range = streakInfo.longestStreakRange {
					let startStr = range.lowerBound.formatted(date: .numeric, time: .omitted)
					let endStr = range.upperBound.formatted(date: .numeric, time: .omitted)
					Text("\(startStr) - \(endStr)")
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
			
			Divider()
			
			// --- SUBSECCIÓN: MÁXIMA INGESTA ---
			if let record = maxRecord {
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Image(systemName: "drop.fill")
							.foregroundStyle(.blue)
						Text("Max daily intake: \(WaterLogFormatters.volumeFromMilliliters(record.totalMilliliters))")
							.font(.headline)
					}
					
					Text(record.date.formatted(date: .numeric, time: .omitted))
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
			
			Divider()
			
			// --- SUBSECCIÓN: MÁXIMA INGESTA (MES) ---
			if let monthly = maxMonthly {
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Image(systemName: "calendar.badge.clock")
							.foregroundStyle(.purple)
						Text("Best month: \(WaterLogFormatters.largeVolumeFromMilliliters(monthly.totalMilliliters))")
							.font(.headline)
					}
					
					// Mostramos el nombre del mes (ej: "octubre 2023")
					Text(monthly.month.formatted(.dateTime.month(.wide).year()))
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.leading, 26)
				}
			}
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 16)
				.strokeBorder(.orange.opacity(0.3), lineWidth: 1)
		)
	}
}

#Preview {
	LongestStreakSection(summaries: [])
}
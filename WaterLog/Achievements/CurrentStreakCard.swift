//
//  CurrentStreakCard.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct CurrentStreakCard: View {
	let streakInfo: StreakResults
	
	init(summaries: [DailyIntakeSummary]) {
		self.streakInfo = Streaks.calculateStreaks(from: summaries)
	}
	
	var body: some View {
		VStack(spacing: 20) {
			Text(streakInfo.currentEvolution.emoji)
				.font(.largeTitle)
				.shadow(radius: 5)
			
			VStack(spacing: 4) {
				AnimatedCounterView(targetValue: streakInfo.currentStreak)
				
				Text("Current streak")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
			
			VStack(spacing: 8) {
				EvolutionProgressView(currentStreak: streakInfo.currentStreak)
				
				// Texto de motivación opcional basado en la evolución
				Text(streakInfo.currentEvolution.evolutionMotivation)
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
			}
			.padding(.horizontal, 10)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 30)
		.background(
			RoundedRectangle(cornerRadius: 24)
				.fill(.secondary.opacity(0.2))
		)
	}
}

#Preview {
	CurrentStreakCard(summaries: MockData.dailySummaries(days: 40, streak: 20))
}

//
//  AchievementsGrid.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct AchievementsGrid: View {
	let achievements: [HistoricalAchievement]
	
	init(summaries: [DailyIntakeSummary]) {
		self.achievements = Streaks.calculateHistoricalAchievements(from: summaries)
	}
	
	var body: some View {
		VStack {
			if achievements.isEmpty {
				VStack(spacing: 10) {
					Image(systemName: "medal.fill")
						.font(.largeTitle)
						.foregroundStyle(.secondary)
					Text("No achievements yet")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.padding(.top, 40)
			} else {
				VStack(alignment: .leading) {
					Text("Your Medals")
						.font(.title2.bold())
						.padding(.bottom, 5)
					
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
						ForEach(achievements) { achievement in
							AchievementCard(achievement: achievement)
						}
					}
				}
			}
		}
	}
}

#Preview {
	AchievementsGrid(summaries: [])
}
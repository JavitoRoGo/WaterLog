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
				ContentUnavailableView("No achievements yet", systemImage: "medal.fill")
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
	AchievementsGrid(summaries: MockData.dailySummaries(days: 40, streak: 35))
}

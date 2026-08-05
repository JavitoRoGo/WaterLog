//
//  AchievementCard.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 03/08/2026.
//

import SwiftUI

struct AchievementCard: View {
    let achievement: HistoricalAchievement
    
	var body: some View {
		VStack(spacing: 12) {
			Text(achievement.type.emoji)
				.font(.system(size: 40))
			
			VStack(spacing: 2) {
				Text(achievement.type.displayName)
					.font(.system(size: 14, weight: .bold))
					.multilineTextAlignment(.center)
					.lineLimit(2)
				
				Text(achievement.type.requirementDescription)
					.font(.system(size: 10))
					.foregroundStyle(.secondary)
			}
			
			Text("x\(achievement.count)")
				.fontWeight(.semibold)
				.foregroundStyle(.blue)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(uiColor: .tertiarySystemBackground))
				.shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
		)
	}
}

#Preview {
	AchievementCard(achievement: .init(type: .waterMaster, count: 1))
}

//
//  StatsGridSection.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 10/08/2026.
//

import SwiftUI

struct StatsGrid: View {
	let coachingContext: CoachingContext
	
	var body: some View {
		LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
			StatCard(
				title: "Streak",
				value: "\(coachingContext.metrics.currentStreak) days",
				icon: "flame.fill",
				color: .orange
			)
			
			StatCard(
				title: "Success",
				value: "\(coachingContext.metrics.successRate.formatted(.percent.precision(.fractionLength(0))))",
				icon: "checkmark.circle.fill",
				color: .blue
			)
			
			StatCard(
				title: "Stability",
				value: "\(coachingContext.metrics.stabilityScore.formatted(.percent.precision(.fractionLength(0))))",
				icon: "shield.fill",
				color: .green
			)
			
			StatCard(
				title: "Trend",
				value: coachIconText,
				icon: "chart.line.uptrend.xyaxis",
				color: .purple
			)
		}
	}
	
	private var coachIconText: LocalizedStringResource {
		switch coachingContext.metrics.consumptionTrend {
		case .increasing: return "Up"
		case .decreasing: return "Down"
		case .stable: return "Steady"
		case .unknown: return "--"
		}
	}
}

#Preview {
	StatsGrid(coachingContext: MockData.coachingContextWarning)
}

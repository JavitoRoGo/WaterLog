//
//  ConsumptionTrendView.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 05/08/2026.
//

import SwiftUI

struct ConsumptionTrendSection: View {
	let trend: TrendResult
	
	init(summaries: [DailyIntakeSummary]) {
		self.trend = IntakeAnalytics.calculateConsumptionTrend(from: summaries)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("Consumption Trend")
					.font(.headline)
				Spacer()
				Image(systemName: trend.isImproving ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.downtrend.xyaxis.circle.fill")
					.foregroundStyle(trend.isImproving ? .green : .red)
			}
			
			VStack(alignment: .leading, spacing: 8) {
				Text(trend.message)
					.font(.subheadline)
					.foregroundStyle(.primary)
				
				HStack(spacing: 15) {
					TrendMetricView(label: "Last 7d", value: WaterLogFormatters.volumeFromMilliliters(trend.shortTermAverage))
					Divider().frame(height: 30)
					TrendMetricView(label: "Last 30d", value: WaterLogFormatters.volumeFromMilliliters(trend.longTermAverage))
				}
				.padding(.top, 5)
			}
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(uiColor: .secondarySystemBackground))
		)
	}
}

#Preview {
	ConsumptionTrendSection(summaries: MockData.dailySummaries(days: 30, streak: 10))
}

import SwiftUI

struct WeeklyEvolutionSection: View {
    let result: WeeklyEvolutionResult
	
	init(summaries: [DailyIntakeSummary]) {
		self.result = IntakeAnalytics.calculateWeeklyEvolution(from: summaries)
	}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Evolution")
                    .font(.headline)
                Spacer()
				if let _ = result.percentageChange {
					Image(systemName: result.isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
						.foregroundStyle(result.isPositive ? .green : .red)
						.font(.largeTitle)
				} else {
					Image(systemName: "chart.bar")
						.foregroundStyle(.secondary)
				}
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let change = result.percentageChange {
                    HStack(alignment: .firstTextBaseline) {
						Text("\(result.isPositive ? "+" : "")\(change.formatted(.percent.precision(.fractionLength(0...2))))")
                            .font(.title2.bold())
                            .foregroundStyle(result.isPositive ? .green : .red)
                        
                        Text("vs last week")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Not enough data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 15) {
					TrendMetricView(label: "This week", value: WaterLogFormatters.volumeFromMilliliters(result.currentWeekTotal))
                    Divider().frame(height: 24)
					TrendMetricView(label: "Previous week", value: WaterLogFormatters.volumeFromMilliliters(result.previousWeekTotal))
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
    WeeklyEvolutionSection(summaries: MockData.dailySummaries(days: 21, streak: 9))
        .padding()
}

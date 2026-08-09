import SwiftUI

struct StabilitySection: View {
    let summaries: [DailyIntakeSummary]
	@State private var analysisPeriod: AnalysisPeriod = .lastMonth
    
    var result: StabilityResult {
		IntakeAnalytics.calculateStability(from: summaries, daysToAnalyze: analysisPeriod)
	}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stability Index")
                    .font(.headline)
                Spacer()
                Image(systemName: result.isStable ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.isStable ? .green : .orange)
					.font(.largeTitle)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Visualización del Score de Estabilidad
                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                        
                        Circle()
                            .trim(from: 0, to: result.stabilityScore)
                            .stroke(
                                result.isStable ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
						Text("\(result.stabilityScore.formatted(.percent.precision(.fractionLength(0))))")
                            .font(.caption.bold())
                    }
                    .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
						Text(result.title)
                            .font(.subheadline.bold())
                        
                        Text(result.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Detalles técnicos simplificados
                HStack {
					TrendMetricView(label: "Daily Variation", value: "±\(WaterLogFormatters.volumeFromMilliliters(result.variabilityValue))")
                    Spacer()
					
					TrendMetricView(label: "Avg. Intake", value: WaterLogFormatters.volumeFromMilliliters(result.averageDailyIntake))
                }
				
				HStack {
					Spacer()
					Menu {
						ForEach(AnalysisPeriod.allCases) { period in
							Button(period.periodLabel) {
								analysisPeriod = period
							}
						}
					} label: {
						HStack(spacing: 2) {
							Text(analysisPeriod.periodLabel)
							Image(systemName: "chevron.down")
								.foregroundStyle(.secondary)
						}
						.font(.caption2)
					}
				}
				.foregroundStyle(.secondary)
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
    // Mock de datos para un usuario con mucha variabilidad
    let mockSummaries = [
		DailyIntakeSummary(date: .now, totalMilliliters: 3000, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-86400), totalMilliliters: 500, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-172800), totalMilliliters: 2500, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-259200), totalMilliliters: 3000, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-345600), totalMilliliters: 1000, dailyGoal: 2000)
    ]
    
	StabilitySection(summaries: mockSummaries)
        .padding()
}

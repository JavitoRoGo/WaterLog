import SwiftUI

struct PredictiveInsightsSection: View {
    let summaries: [DailyIntakeSummary]
	@State private var analysisPeriod: AnalysisPeriod = .lastMonth
	
	var result: RiskPredictionResult {
		IntakeAnalytics.calculateRiskPrediction(from: summaries, daysToAnalyze: analysisPeriod)
	}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Predictive Insights")
                    .font(.headline)
                Spacer()
                RiskPredictionIcon(riskLevel: result.riskLevel)
                    .font(.largeTitle)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(result.message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Indicador visual de nivel de riesgo/confianza
                HStack(spacing: 4) {
                    let filledBars = Int((result.confidenceScore * 5).rounded())
                    
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(index < filledBars ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.2))
                            .frame(height: 6)
                    }
                }
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
					.font(.caption)
				}
			}
			.foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(riskBackground)
        )
    }

    private var riskBackground: Color {
        switch result.riskLevel {
		case .low: return Color.secondary.opacity(0.2)
        case .medium: return Color.orange.opacity(0.1)
        case .high: return Color.red.opacity(0.1)
        }
    }
}

private struct RiskPredictionIcon: View {
    let riskLevel: RiskLevel

    @ViewBuilder
    var body: some View {
        switch riskLevel {
        case .low:
            Image(systemName: "sparkles")
                .foregroundStyle(.blue)
        case .medium:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
        case .high:
            Image(systemName: "bolt.shield.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    // Mock de datos corregido: eliminada la propiedad reachedGoal del init
    let mockSummaries = [
        DailyIntakeSummary(date: .now, totalMilliliters: 2500, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-86400), totalMilliliters: 300, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-172800), totalMilliliters: 400, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-259200), totalMilliliters: 2100, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-345600), totalMilliliters: 200, dailyGoal: 2000),
        DailyIntakeSummary(date: .now.addingTimeInterval(-432000), totalMilliliters: 150, dailyGoal: 2000)
    ]
    
    PredictiveInsightsSection(summaries: mockSummaries)
        .padding()
}

import SwiftUI

struct GoalSuccessRateSection: View {
	let summaries: [DailyIntakeSummary]
	@State private var analysisPeriod: AnalysisPeriod = .lastMonth
	
	var result: SuccessRateResult {
		IntakeAnalytics.calculateSuccessRate(from: summaries, daysToAnalyze: analysisPeriod)
	}
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goal Success Rate")
                    .font(.headline)
                Spacer()
                Image(systemName: "target")
                    .foregroundStyle(.blue)
                    .font(.largeTitle)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                // Porcentaje principal y mensaje
                HStack(alignment: .bottom) {
                    Text("\(result.rate.formatted(.percent.precision(.fractionLength(0))))")
                        .font(.title3)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)
                }
                
                // Barra de progreso horizontal
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * result.rate, height: 12)
                    }
                }
                .frame(height: 12)
                
                // Detalle de días cumplidos
                HStack {
                    Text("\(result.daysMet) out of \(result.totalDays) days met")
						.font(.caption)
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
                .fill(.secondary.opacity(0.2))
        )
    }
}

#Preview {
    // Mock de datos con un 80% de éxito (24 de 30 días)
    let mockSummaries = (0..<30).map { i in
        DailyIntakeSummary(
			date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!,
			totalMilliliters: Int.random(in: 1000...3000),
            dailyGoal: 2000
        )
    }
    
	GoalSuccessRateSection(summaries: mockSummaries)
        .padding()
}

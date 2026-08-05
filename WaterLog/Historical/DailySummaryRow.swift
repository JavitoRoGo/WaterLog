import SwiftUI

struct DailySummaryRow: View {
    let summary: DailyIntakeSummary

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(WaterLogFormatters.weekday(summary.date).capitalized)
                Text(WaterLogFormatters.shortDayAndMonth(summary.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(WaterLogFormatters.percentage(summary.percentage))
                .foregroundStyle(.secondary)

            Spacer()
			
            if summary.reachedGoal {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
			
            VStack {
            	Text(WaterLogFormatters.volumeFromMilliliters(summary.totalMilliliters))
					.bold()
				Text(WaterLogFormatters.volumeFromMilliliters(summary.dailyGoal))
					.font(.caption)
					.foregroundStyle(.secondary)
            }
        }
        .contentShape(.rect)
    }
}

#Preview {
	DailySummaryRow(summary: MockData.dailySummaries(days: 2, streak: 1)[0])
}


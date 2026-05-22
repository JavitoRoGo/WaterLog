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
			
            Text("\(WaterLogFormatters.milliliters(summary.totalMilliliters)) ml")
                .bold()
        }
        .contentShape(.rect)
    }
}

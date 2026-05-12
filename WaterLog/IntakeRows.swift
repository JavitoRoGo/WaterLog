import SwiftUI

struct IntakeEntryRow: View {
    let entry: WaterIntakeEntry

    var body: some View {
        HStack {
            Text(WaterLogFormatters.time(entry.date))
            Spacer()
            Text("\(WaterLogFormatters.milliliters(Int(entry.amountMeasurement.converted(to: .milliliters).value))) ml")
                .bold()
        }
    }
}

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

struct MonthSummaryRow: View {
    let summary: MonthIntakeSummary

    var body: some View {
        HStack {
            Text(WaterLogFormatters.month(summary.monthStart).capitalized)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(WaterLogFormatters.milliliters(summary.averageDailyMilliliters)) ml/día")
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(WaterLogFormatters.milliliters(summary.totalMilliliters)) ml")
                .bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(.rect)
    }
}

struct YearSummaryRow: View {
    let summary: YearIntakeSummary

    var body: some View {
        HStack {
            Text(WaterLogFormatters.year(summary.yearStart))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(WaterLogFormatters.milliliters(summary.averageDailyMilliliters)) ml/día")
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(WaterLogFormatters.milliliters(summary.totalMilliliters)) ml")
                .bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(.rect)
    }
}

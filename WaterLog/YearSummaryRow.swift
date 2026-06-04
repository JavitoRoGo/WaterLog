import SwiftUI

struct YearSummaryRow: View {
    let summary: YearIntakeSummary

    var body: some View {
        HStack {
            Text(WaterLogFormatters.year(summary.yearStart))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(WaterLogFormatters.milliliters(summary.averageDailyMilliliters)) ml/día")
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(WaterLogFormatters.liters(summary.totalMilliliters)) l")
                .bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(.rect)
    }
}
#Preview {
    YearSummaryRow(summary: YearIntakeSummary(yearStart: .now, totalMilliliters: 730000, averageDailyMilliliters: 2000))
}

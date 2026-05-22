import SwiftUI

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

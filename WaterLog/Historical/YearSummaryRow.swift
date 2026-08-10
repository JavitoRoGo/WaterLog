import SwiftUI

struct YearSummaryRow: View {
    let summary: YearIntakeSummary

    var body: some View {
        HStack {
            Text(WaterLogFormatters.year(summary.yearStart))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(WaterLogFormatters.volumeFromMilliliters(summary.averageDailyMilliliters))/d")
                .frame(maxWidth: .infinity, alignment: .center)

            Text(WaterLogFormatters.largeVolumeFromMilliliters(summary.totalMilliliters))
                .bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(.rect)
    }
}
#Preview {
    YearSummaryRow(summary: YearIntakeSummary(yearStart: .now, totalMilliliters: 730000, averageDailyMilliliters: 2000))
}

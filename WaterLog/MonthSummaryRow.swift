import SwiftUI

struct MonthSummaryRow: View {
    let summary: MonthIntakeSummary

    var body: some View {
        HStack {
            Text(WaterLogFormatters.month(summary.monthStart).capitalized)
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
    MonthSummaryRow(summary: MonthIntakeSummary(monthStart: .now, totalMilliliters: 45000, averageDailyMilliliters: 1500))
}

import SwiftUI

struct DailyProgressSection: View {
    let totalMilliliters: Int
    let addEntry: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressRingView(totalMilliliters: totalMilliliters, goalMilliliters: IntakeConstants.dailyGoalMilliliters, lineWidth: 24, font: .largeTitle)
                .frame(maxHeight: 280)

            Text("\(WaterLogFormatters.percentage(IntakeAnalytics.percentage(for: totalMilliliters))) del objetivo diario")
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            IntakeAmountButtons(addEntry: addEntry)
        }
    }
}

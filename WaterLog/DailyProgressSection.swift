import SwiftUI

struct DailyProgressSection: View {
    let totalMilliliters: Int
    let dailyGoalMilliliters: Int
    let addEntry: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressRingView(totalMilliliters: totalMilliliters, goalMilliliters: dailyGoalMilliliters, lineWidth: 24, font: .largeTitle)
                .frame(maxHeight: 280)

            Text("\(WaterLogFormatters.percentage(IntakeAnalytics.percentage(for: totalMilliliters, goal: dailyGoalMilliliters))) daily goal")
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            IntakeAmountButtons(addEntry: addEntry)
        }
    }
}
#Preview {
	DailyProgressSection(totalMilliliters: 1200, dailyGoalMilliliters: 2000, addEntry: {_ in })
}


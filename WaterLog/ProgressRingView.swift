import SwiftUI

struct ProgressRingView: View {
    let totalMilliliters: Int
    let goalMilliliters: Int
	let lineWidth: CGFloat
	let font: Font

    private var progress: Double {
        IntakeAnalytics.progress(for: totalMilliliters)
    }

    private var reachedGoal: Bool {
        totalMilliliters >= goalMilliliters
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(reachedGoal ? .green : .blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)
                .animation(.easeInOut(duration: 0.35), value: reachedGoal)

            VStack(spacing: 8) {
                Text(WaterLogFormatters.volumeFromMilliliters(totalMilliliters))
                    .font(font)
                    .bold()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.5), value: totalMilliliters)

                if reachedGoal {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal)
    }
}

#Preview {
	ProgressRingView(totalMilliliters: 1_250, goalMilliliters: IntakeConstants.dailyGoalMilliliters, lineWidth: 24, font: .largeTitle)
        .padding()
}

import SwiftUI

struct IntakeAmountButtons: View {
    let addEntry: (Int) -> Void

    private let amounts = [125, 250, 500]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(amounts, id: \.self) { amount in
                Button("\(WaterLogFormatters.milliliters(amount)) ml") {
                    addEntry(amount)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
}

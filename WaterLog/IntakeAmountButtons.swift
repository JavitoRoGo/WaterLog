import SwiftUI

struct IntakeAmountButtons: View {
    let addEntry: (Int) -> Void

	// Usamos UserDefaults con el App Group para leer los mismos valores que la App
	@AppStorage("buttonAmount1", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount1: Int = 125
	@AppStorage("buttonAmount2", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount2: Int = 250
	@AppStorage("buttonAmount3", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount3: Int = 500

    private var amounts: [Int] {
        [amount1, amount2, amount3]
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(amounts, id: \.self) { amount in
                Button(WaterLogFormatters.volumeFromMilliliters(amount)) {
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
#Preview {
	IntakeAmountButtons(addEntry: {_ in })
}

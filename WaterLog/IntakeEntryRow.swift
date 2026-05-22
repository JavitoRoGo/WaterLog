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

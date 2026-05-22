import SwiftUI
import SwiftData

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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WaterIntakeEntry.self, configurations: config)
    let entry = WaterIntakeEntry(date: .now, amount: 250)
    container.mainContext.insert(entry)
    
    return IntakeEntryRow(entry: entry)
        .modelContainer(container)
}

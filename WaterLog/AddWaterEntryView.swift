import SwiftData
import SwiftUI
import WidgetKit

struct AddWaterEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let initialDate: Date
    @State private var selectedDate: Date
    @State private var selectedAmount: Int = 250

    init(initialDate: Date) {
        self.initialDate = initialDate
        _selectedDate = State(initialValue: Self.initialSelectedDate(for: initialDate))
    }

    private let amounts = Array(stride(from: 250, through: 5000, by: 250))

    private static func initialSelectedDate(for date: Date, calendar: Calendar = .current) -> Date {
        let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
        return calendar.date(
            bySettingHour: time.hour ?? 12,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: date
        ) ?? date
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date and hour") {
                    DatePicker("Date selection", selection: $selectedDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                Section("Quantity") {
                    Picker("Quantity", selection: $selectedAmount) {
                        ForEach(amounts, id: \.self) { amount in
                            Text(WaterLogFormatters.volumeFromMilliliters(amount)).tag(amount)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("New entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let entry = WaterIntakeEntry(date: selectedDate, amount: selectedAmount)
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            IntakeAnalytics.reloadWidgetTimelineIfNeeded(for: entry.date)
            dismiss()
        } catch {
            print("Error while saving: \(error)")
        }
    }
}
#Preview {
    AddWaterEntryView(initialDate: .now)
}


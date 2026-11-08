import SwiftData
import SwiftUI
import WidgetKit

struct AddWaterEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let initialDate: Date
    @State private var selectedDate: Date
    @State private var selectedAmount: Int = 0
    
    // Nuevos estados para la entrada manual
    @State private var customAmountText: String = ""
    @State private var selectedUnit: UnitVolume = .milliliters

    init(initialDate: Date) {
        self.initialDate = initialDate
        _selectedDate = State(initialValue: Self.initialSelectedDate(for: initialDate))
    }

    private let amounts = Array(stride(from: 0, through: 5000, by: 250))
    
    // Unidades permitidas para el picker de la nueva funcionalidad
    private let units: [(String, UnitVolume)] = [
        ("ml", .milliliters),
        ("fl oz", .fluidOunces),
        ("imp fl oz", .imperialFluidOunces)
    ]

    private static func initialSelectedDate(for date: Date, calendar: Calendar = .current) -> Date {
        let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
        return calendar.date(
            bySettingHour: time.hour ?? 12,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: date
        ) ?? date
    }
	
	private enum QuantitySource: CaseIterable, Identifiable {
		case presets
		case custom
		
		var id: Self { self }
		
		var title: LocalizedStringKey {
			switch self {
			case .presets: return "Presets"
			case .custom: return "Custom"
			}
		}
	}
	@State private var quantitySource: QuantitySource = .presets
	@State private var showErrorAlert = false
	@State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Date and hour") {
                    DatePicker("Date selection", selection: $selectedDate, in: Date.distantPast...Date(), displayedComponents: [.date, .hourAndMinute])
                }

				Section("Quantity") {
					Picker("Quantity source", selection: $quantitySource.animation()) {
						ForEach(QuantitySource.allCases) { source in
							Text(source.title).tag(source)
						}
					}
					.pickerStyle(.segmented)
					
					if quantitySource == .presets {
						Picker("Quantity", selection: $selectedAmount) {
							ForEach(amounts, id: \.self) { amount in
								Text(WaterLogFormatters.volumeFromMilliliters(amount)).tag(amount)
							}
						}
						.pickerStyle(.wheel)
					} else {
						HStack {
							TextField("Amount", text: $customAmountText)
								.keyboardType(.decimalPad)
							
							Picker("Volume unit", selection: $selectedUnit) {
								ForEach(units, id: \.1) { unitName, unit in
									Text(unitName).tag(unit)
								}
							}
							.pickerStyle(.menu)
							.labelsHidden()
							.disabled(customAmountText.isEmpty)
						}
					}
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
					.disabled((quantitySource == .presets && selectedAmount == 0) || (quantitySource == .custom && customAmountText.isEmpty))
                }
            }
            .alert("Invalid amount", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
		var finalAmount: Int = quantitySource == .presets ? selectedAmount : 0
		
        // Si hay una entrada manual, calculamos su valor en ml
		if quantitySource == .custom, !customAmountText.isEmpty, let customValue = Double(customAmountText) {
            let measurement = Measurement(value: customValue, unit: selectedUnit)
            let inMilliliters = measurement.converted(to: .milliliters)
            finalAmount = Int(inMilliliters.value.rounded())
        }
		
        // Comprobación: El valor debe ser mayor que cero
        guard finalAmount > 0 else {
            errorMessage = "Amount must be positive and greater than zero."
            showErrorAlert = true
            return
        }
		
        let entry = WaterIntakeEntry(date: selectedDate, amount: finalAmount)
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

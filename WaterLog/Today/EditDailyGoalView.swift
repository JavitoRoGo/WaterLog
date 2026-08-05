import SwiftUI
import SwiftData
import WidgetKit

struct EditDailyGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // La fecha inyectada para mostrar y guardar el objetivo
    let date: Date
	let existingGoal: Int
    
    // Valor y unidad local para el editor
    @State private var goalAmount: Double = 0
	@State private var goalUnit: SettingsView.VolumeUnit = .milliliters
    
    // Estado para la alerta de confirmación
    @State private var showingConfirmationAlert = false
    
    // El objetivo que se va a guardar (ya convertido a ml)
    @State private var amountToSaveInML: Int = 0
	
	var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Section("Daily Goal") {
                    HStack {
                        TextField("Amount", value: $goalAmount, format: .number.precision(.fractionLength(goalUnit.unit == .milliliters ? 0 : 2)))
                            .keyboardType(.decimalPad)
							.textFieldStyle(.roundedBorder)
                        
                        Picker("Volume unit", selection: $goalUnit) {
                            ForEach(SettingsView.VolumeUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    HStack {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("Save") {
                            prepareSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(goalAmount <= 0)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Update your daily goal")
            .navigationBarTitleDisplayMode(.inline)
			.onAppear {
				setupGoal()
			}
            .alert("Daily goal saved", isPresented: $showingConfirmationAlert) {
                Button("OK") {
                    saveGoal()
                    dismiss()
                }
            } message: {
                Text("Your daily goal has been successfully updated.")
            }
        }
    }
	
	private func setupGoal() {
		let units = IntakeConstants.appLocale.measurementSystem
		goalUnit = switch units {
		case .us: .fluidOunces
		case .uk: .imperialFluidOunces
		default: .milliliters
		}
		let measurement = Measurement(value: Double(existingGoal), unit: UnitVolume.milliliters)
		goalAmount = measurement.converted(to: goalUnit.unit).value
	}

    private func prepareSave() {
        // Convertimos la entrada del usuario a mililitros antes de mostrar la alerta/guardar
        let measurement = Measurement(value: goalAmount, unit: goalUnit.unit)
        let mlValue = measurement.converted(to: .milliliters)
        amountToSaveInML = Int(mlValue.value.rounded())
        showingConfirmationAlert = true
    }

    private func saveGoal() {
        let calendar = Calendar.current
        // Normalizamos la fecha inyectada para asegurar que el DailyGoal se guarde al inicio del día (00:00:00)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: components) else { return }

        // Primero intentamos borrar si ya existe uno para evitar duplicados (debido a la lógica de @Attribute(.unique))
        let predicate = #Predicate<DailyGoal> { goal in
            goal.date == normalizedDate
        }
        let descriptor = FetchDescriptor<DailyGoal>(predicate: predicate)
        
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        }

        // Creamos el nuevo registro
        let newGoal = DailyGoal(date: normalizedDate, amount: amountToSaveInML)
        modelContext.insert(newGoal)
        
        do {
            try modelContext.save()
			WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving goal: \(error)")
        }
    }
}

#Preview {
    EditDailyGoalView(date: .now, existingGoal: 4000)
}

import SwiftUI
import WidgetKit
import UniformTypeIdentifiers
import SwiftData

// MARK: - Settings View

struct SettingsView: View {
	// Usamos UserDefaults con el App Group para leer los mismos valores que la App
	@AppStorage("buttonAmount1", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount1: Int = 125
	@AppStorage("buttonAmount2", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount2: Int = 250
	@AppStorage("buttonAmount3", store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var amount3: Int = 500
    
	@AppStorage(WaterLogStore.keyForStandardGoalMilliliters, store: UserDefaults(suiteName: WaterLogStore.appGroupIdentifier)!) private var standardGoal: Int = IntakeConstants.defaultGoalMilliliters
	@State private var standardGoalUnit: VolumeUnit = .milliliters
    
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [WaterIntakeEntry]
	private var dtoHelper: DTOHelper {
		.init(entries: entries, modelContext: modelContext)
	}

    // Local state for editing values
    @State private var row1Value: Double = 0
    @State private var row1Unit: VolumeUnit = .milliliters
    
    @State private var row2Value: Double = 0
    @State private var row2Unit: VolumeUnit = .milliliters
    
    @State private var row3Value: Double = 0
    @State private var row3Unit: VolumeUnit = .milliliters

    // Local state to track if changes have been made
    @State private var row1IsDirty = false
    @State private var row2IsDirty = false
    @State private var row3IsDirty = false

    // State to remember the last saved values for comparison
    @State private var row1LastSaved: (value: Double, unit: VolumeUnit) = (0, .milliliters)
    @State private var row2LastSaved: (value: Double, unit: VolumeUnit) = (0, .milliliters)
    @State private var row3LastSaved: (value: Double, unit: VolumeUnit) = (0, .milliliters)

    // State for Export/Import
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportAlert = false
    @State private var showImportError = false
    
    // Local state for Standard Goal editing
    @State private var editingStandardGoal: Double = 0

    enum VolumeUnit: String, CaseIterable, Identifiable {
        case milliliters = "ml"
        case imperialFluidOunces = "imp fl oz"
        case fluidOunces = "fl oz"
        
        var id: Self { self }
        
        var unit: UnitVolume {
            switch self {
            case .milliliters: return .milliliters
            case .imperialFluidOunces: return .imperialFluidOunces
            case .fluidOunces: return .fluidOunces
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Add Buttons") {
                    amountRow(title: "Button 1", value: $row1Value, unit: $row1Unit, isDirty: $row1IsDirty, saveAction: { save(value: row1Value, unit: row1Unit, to: &amount1, rowIndex: 1) })
                        .onChange(of: row1Value) { _, newValue in checkDirty(rowIndex: 1, value: newValue, unit: row1Unit) }
                        .onChange(of: row1Unit) { _, newValue in checkDirty(rowIndex: 1, value: row1Value, unit: newValue) }

                    amountRow(title: "Button 2", value: $row2Value, unit: $row2Unit, isDirty: $row2IsDirty, saveAction: { save(value: row2Value, unit: row2Unit, to: &amount2, rowIndex: 2) })
                        .onChange(of: row2Value) { _, newValue in checkDirty(rowIndex: 2, value: newValue, unit: row2Unit) }
                        .onChange(of: row2Unit) { _, newValue in checkDirty(rowIndex: 2, value: row2Value, unit: newValue) }

                    amountRow(title: "Button 3", value: $row3Value, unit: $row3Unit, isDirty: $row3IsDirty, saveAction: { save(value: row3Value, unit: row3Unit, to: &amount3, rowIndex: 3) })
                        .onChange(of: row3Value) { _, newValue in checkDirty(rowIndex: 3, value: newValue, unit: row3Unit) }
                        .onChange(of: row3Unit) { _, newValue in checkDirty(rowIndex: 3, value: row3Value, unit: newValue) }
                }

                Section {
                    HStack {
                        Text("Default value")
                        Spacer()
						TextField("Amount", value: $editingStandardGoal, format: .number.precision(.fractionLength(standardGoalUnit.unit == .milliliters ? 0 : 2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
						Picker("Volume unit", selection: $standardGoalUnit) {
							ForEach(VolumeUnit.allCases) { volumeUnit in
								Text(volumeUnit.rawValue).tag(volumeUnit)
							}
						}
						.pickerStyle(.menu)
						.labelsHidden()
						
						Button {
							if editingStandardGoal > 0 {
								// Realizamos la conversión a mililitros antes de guardar
								let measurement = Measurement(value: editingStandardGoal, unit: standardGoalUnit.unit)
								let mlValue = measurement.converted(to: .milliliters)
								standardGoal = Int(mlValue.value.rounded())
							}
						} label: {
							Text("Save").font(.caption2)
						}
						.buttonStyle(.borderedProminent)
						.disabled(editingStandardGoal <= 0)
                    }
				} header: {
					Text("Daily Goal")
				} footer: {
					Text("settings.dailyGoal.footer")
				}
				
				Section("Data base") {
					// Exportación mediante ShareLink (más versátil que fileExporter para JSONs pequeños)
					if let exportURL = dtoHelper.generateExportURL() {
						ShareLink(item: exportURL, preview: SharePreview("WaterLog Backup", image: Image(systemName: "doc.text"))) {
							Label("Export data", systemImage: "square.and.arrow.up")
						}
					}

					Button {
						isImporting = true
					} label: {
						Label("Import data", systemImage: "square.and.arrow.down")
					}
				}
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupRows()
                editingStandardGoal = Double(standardGoal)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json], // El backup es un JSON
                allowsMultipleSelection: false
			) { result in
				switch result {
				case .success(let urls):
					guard let selectedURL = urls.first else { return }
					// Llamamos al helper y gestionamos el resultado localmente
					let importResult = dtoHelper.importJSON(from: selectedURL)
					
					switch importResult {
					case .success:
						showImportAlert = true
					case .failure(let error):
						importError = error.localizedDescription
						showImportError = true
					}
					
				case .failure(let error):
					importError = error.localizedDescription
					showImportError = true
				}
			}
            .alert("Data imported.", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data base has been successfully updated.")
            }
            .alert("Import error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "Unknown error")
            }
        }
    }

    // MARK: - UI Helpers & Existing Logic

    @ViewBuilder
    private func amountRow(
        title: LocalizedStringKey,
        value: Binding<Double>,
        unit: Binding<VolumeUnit>,
        isDirty: Binding<Bool>,
        saveAction: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            TextField("Amount", value: value, format: .number.precision(.fractionLength(unit.wrappedValue.unit == .milliliters ? 0 : 2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            
            Picker("Volume unit", selection: unit) {
                ForEach(VolumeUnit.allCases) { volumeUnit in
                    Text(volumeUnit.rawValue).tag(volumeUnit)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Button(action: saveAction) {
                Text("Save").font(.caption2)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isDirty.wrappedValue || value.wrappedValue <= 0)
        }
    }

    private func setupRows() {
        initializeRow(amount: amount1, value: &row1Value, unit: &row1Unit, lastSaved: &row1LastSaved, isDirty: &row1IsDirty)
        initializeRow(amount: amount2, value: &row2Value, unit: &row2Unit, lastSaved: &row2LastSaved, isDirty: &row2IsDirty)
        initializeRow(amount: amount3, value: &row3Value, unit: &row3Unit, lastSaved: &row3LastSaved, isDirty: &row3IsDirty)
    }

    private func initializeRow(amount: Int, value: inout Double, unit: inout VolumeUnit, lastSaved: inout (value: Double, unit: VolumeUnit), isDirty: inout Bool) {
        let measurement = Measurement(value: Double(amount), unit: UnitVolume.milliliters)
        unit = detectPreferredUnit()
        let converted = measurement.converted(to: unit.unit)
        value = converted.value
        lastSaved = (value: value, unit: unit)
        isDirty = false
    }

    private func checkDirty(rowIndex: Int, value: Double, unit: VolumeUnit) {
        switch rowIndex {
        case 1: row1IsDirty = (value != row1LastSaved.value || unit != row1LastSaved.unit)
        case 2: row2IsDirty = (value != row2LastSaved.value || unit != row2LastSaved.unit)
        case 3: row3IsDirty = (value != row3LastSaved.value || unit != row3LastSaved.unit)
        default: break
        }
    }

    private func save(value: Double, unit: VolumeUnit, to storage: inout Int, rowIndex: Int) {
		guard value > 0 else { return }
		let measurement = Measurement(value: value, unit: unit.unit)
        let mlValue = measurement.converted(to: .milliliters)
        storage = Int(mlValue.value.rounded())
		WidgetCenter.shared.reloadAllTimelines()
        
        switch rowIndex {
        case 1: row1LastSaved = (value, unit); row1IsDirty = false
        case 2: row2LastSaved = (value, unit); row2IsDirty = false
        case 3: row3LastSaved = (value, unit); row3IsDirty = false
        default: break
        }
    }
    
    private func detectPreferredUnit() -> VolumeUnit {
        let locale = IntakeConstants.appLocale
        switch locale.measurementSystem {
        case .us: return .fluidOunces
        case .uk: return .imperialFluidOunces
        default: return .milliliters
        }
    }
}

#Preview {
    SettingsView()
}

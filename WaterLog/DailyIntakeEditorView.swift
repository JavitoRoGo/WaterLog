import SwiftData
import SwiftUI
import Playgrounds

struct DailyIntakeEditorContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterIntakeEntry.date, order: .reverse) private var entries: [WaterIntakeEntry]
    @State private var saveError: String?
    @State private var showingAddSheet = false

    let date: Date
    let title: String
    let emptyTitle: String
    let emptyDescription: String?

    private var dayEntries: [WaterIntakeEntry] {
        IntakeAnalytics.entries(entries, on: date)
    }

    private var totalMilliliters: Int {
        dayEntries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            DailyProgressSection(totalMilliliters: totalMilliliters, addEntry: addEntry)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 16, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            Section {
                ForEach(dayEntries) { entry in
                    IntakeEntryRow(entry: entry)
                        .swipeActions(edge: .trailing) {
                            Button("Eliminar", systemImage: "trash", role: .destructive) {
                                delete(entry)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if dayEntries.isEmpty {
                ContentUnavailableView(emptyTitle, systemImage: "drop", description: emptyDescription.map(Text.init))
                    .offset(y: 180)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
				Button("Añadir", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWaterEntryView(initialDate: date)
        }
        .alert("No se pudo guardar", isPresented: errorBinding) {
            Button("Aceptar", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { isPresented in
                if !isPresented {
                    saveError = nil
                }
            }
        )
    }

    private func addEntry(amount: Int) {
        let entry = WaterIntakeEntry(date: entryDate(), amount: amount)
        modelContext.insert(entry)
        saveChanges()
    }

    private func delete(_ entry: WaterIntakeEntry) {
        modelContext.delete(entry)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func entryDate(calendar: Calendar = .current) -> Date {
        if calendar.isDateInToday(date) {
            return .now
        }

        let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
        return calendar.date(
            bySettingHour: time.hour ?? 12,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: date
        ) ?? date
    }
}

struct AddWaterEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let initialDate: Date
    @State private var selectedDate: Date
    @State private var selectedAmount: Int = 100

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
                Section("Fecha y hora") {
                    DatePicker("Seleccionar fecha", selection: $selectedDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                Section("Cantidad (ml)") {
                    Picker("Cantidad", selection: $selectedAmount) {
                        ForEach(amounts, id: \.self) { amount in
                            Text("\(amount) ml").tag(amount)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Nuevo registro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
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
            dismiss()
        } catch {
            print("Error al guardar: \(error)")
        }
    }
}

struct DayDetailView: View {
    let date: Date

    var body: some View {
        DailyIntakeEditorContent(
            date: date,
            title: WaterLogFormatters.shortDayAndMonth(date),
            emptyTitle: "Sin registros",
            emptyDescription: "Añade una cantidad para este día."
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DailyProgressSection: View {
    let totalMilliliters: Int
    let addEntry: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
			ProgressRingView(totalMilliliters: totalMilliliters, goalMilliliters: IntakeConstants.dailyGoalMilliliters, lineWidth: 24, font: .largeTitle)
                .frame(maxHeight: 280)

            Text("\(WaterLogFormatters.percentage(IntakeAnalytics.percentage(for: totalMilliliters))) del objetivo diario")
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            IntakeAmountButtons(addEntry: addEntry)
        }
    }
}

private struct IntakeAmountButtons: View {
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

#Preview {
    NavigationStack {
        DayDetailView(date: .now)
    }
    .modelContainer(for: WaterIntakeEntry.self, inMemory: true)
}

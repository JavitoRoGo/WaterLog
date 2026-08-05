import SwiftUI
import SwiftData

extension View {
    /// Crea un contenedor de SwiftData en memoria con datos de prueba para una cantidad específica de días.
    /// - Parameter days: El número de días hacia atrás a partir de hoy que se deben generar.
    /// - Returns: La vista con el contenedor inyectado.
    func previewContainer(days: Int) -> some View {
        let container = createMockContainer(days: days)
        return self.modelContainer(container)
    }

    @MainActor
    private func createMockContainer(days: Int) -> ModelContainer {
        let schema = Schema([WaterIntakeEntry.self, DailyGoal.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        // Parámetros para los datos de prueba
        let goalAmount = 2000
        let entryAmount = 2500 // Supera el objetivo para crear rachas
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // 1. Creamos un objetivo para el día
                let goal = DailyGoal(date: date, amount: goalAmount)
                context.insert(goal)
                
                // 2. Registramos una entrada de agua que cumple el objetivo
                // Alternamos algunos días con menos agua para que las rachas no sean infinitas si se desea probar fallos
                let currentAmount = (i % 7 == 0) ? 1000 : entryAmount
                let entry = WaterIntakeEntry(date: date, amount: currentAmount)
                context.insert(entry)
            }
        }
        
        return container
    }
}
// MARK: - Mock Data Generators

struct MockData {
    /// Genera un array de resúmenes diarios artificiales para pruebas unitarias o vistas que no usen SwiftData directamente.
    /// - Parameter days: El número de días a generar.
    /// - Returns: Un array de `DailyIntakeSummary`.
	static func dailySummaries(days: Int, streak: Int) -> [DailyIntakeSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var summaries: [DailyIntakeSummary] = []
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let goal = 2000
                // Simulamos que cada X días no llega al objetivo
                let amount = (i % streak == 0) ? 1200 : 2400
                
                summaries.append(DailyIntakeSummary(
                    date: date,
                    totalMilliliters: amount,
                    dailyGoal: goal
                ))
            }
        }
        
        return summaries.sorted { $0.date < $1.date }
    }
}


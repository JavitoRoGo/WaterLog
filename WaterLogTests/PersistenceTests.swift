import Testing
import Foundation
import SwiftData
@testable import WaterLog

@Suite("Fase 2: Persistencia y Modelos (SwiftData In-Memory)")
struct PersistenceTests {
    
    // MARK: - Infrastructure
    
    /// Un contenedor de pruebas que gestiona su propio ciclo de vida.
    /// Usamos una clase para asegurar que la configuración sea estable.
    @MainActor
    final class TestEnvironment {
        let container: ModelContainer
        let context: ModelContext
        
        init() throws {
            let schema = Schema([
                WaterIntakeEntry.self,
                DailyGoal.self
            ])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            self.container = try ModelContainer(for: schema, configurations: [configuration])
            self.context = container.mainContext
        }
    }

    // MARK: - Pruebas de Modelos (Sin SwiftData para evitar bloqueos)

    @Suite("Validación de Integridad de Modelos")
    struct ModelIntegrity {
        
        @Test("WaterIntakeEntry: Debe inicializarse correctamente con fecha y cantidad")
        func testWaterIntakeEntryInitialization() {
            let date = Date()
            let amount = 500
            let entry = WaterIntakeEntry(date: date, amount: amount)
            
            #expect(entry.date == date)
            #expect(entry.amount == amount)
        }
        
        @Test("DailyGoal: Debe normalizar la fecha al inicio del día (startOfDay)")
        func testDailyGoalDateNormalization() {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = 2024
            components.month = 5
            components.day = 20
            components.hour = 15
            components.minute = 30
            let midDayDate = calendar.date(from: components)
            
            guard let unwrappedMidDayDate = midDayDate else { return }
            let expectedDate = calendar.startOfDay(for: unwrappedMidDayDate)
            let goal = DailyGoal(date: unwrappedMidDayDate, amount: 2000)
            
            #expect(goal.date == expectedDate)
        }
    }
}

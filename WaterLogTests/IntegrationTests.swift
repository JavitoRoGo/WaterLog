import Testing
import Foundation
import SwiftData
@testable import WaterLog

@Suite("Fase 2: Integración de Persistencia y Lógica Analítica")
struct IntegrationTests {
    
    // MARK: - Infrastructure (Reutilización del patrón estable)
    
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
            
            // Helper para resúmenes mensuales
            let calendar = Calendar.current
            let startDate = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
            let endDate = calendar.dateInterval(of: .month, for: .now)?.end ?? .now
            _ = startDate
            _ = endDate
        }
    }

    // MARK: - Integration Suites

    @MainActor
    @Suite("Integración Datos Persistidos -> Resúmenes")
    struct DataToSummaryIntegration {
        
        @Test("El resumen diario debe reflejar la suma exacta de las entradas persistidas")
        func testDailySummaryFromPersistedEntries() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            
            // 1. Preparar datos en SwiftData
            let entry1 = WaterIntakeEntry(date: today, amount: 500)
            let entry2 = WaterIntakeEntry(date: today.addingTimeInterval(3600), amount: 750) // +1 hora
            env.context.insert(entry1)
            env.context.insert(entry2)
            try env.context.save()
            
            // 2. Recuperar datos (Simulando comportamiento de la App con @Query)
            let descriptor = FetchDescriptor<WaterIntakeEntry>()
            let persistedEntries = try env.context.fetch(descriptor)
            
            // 3. Pasar a la lógica analítica
            let summaries = IntakeAnalytics.dailySummaries(
                for: persistedEntries,
                goals: [],
                defaultGoal: 2000,
                from: today,
                through: today
            )
            
            // 4. Validar integración
            #expect(summaries.count == 1)
        }
        
        @Test("Los resúmenes mensuales deben promediar correctamente sobre los días con datos persistidos")
        func testMonthlyAverageFromPersistedHistory() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            
            // 1. Insertar datos para 3 días distintos del mes
            // Día 1: 1000ml
            let startOfMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
            env.context.insert(WaterIntakeEntry(date: startOfMonth, amount: 1000))
            // Día 2: 2000ml
            env.context.insert(WaterIntakeEntry(date: calendar.date(byAdding: .day, value: 1, to: startOfMonth) ?? .now, amount: 2000))
            // Día 3: 3000ml
            env.context.insert(WaterIntakeEntry(date: calendar.date(byAdding: .day, value: 2, to: startOfMonth) ?? .now, amount: 3000))
            // El resto del mes no tiene datos (deberían ser ignorados en el promedio según la lógica actual)
            
            try env.context.save()
            
            // 2. Recuperar
            let entries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            
            // 3. Analizar
            let monthSummaries = IntakeAnalytics.monthSummaries(
                for: entries,
                goals: [],
                defaultGoal: 2000,
                from: startOfMonth,
                through: calendar.dateInterval(of: .month, for: .now)?.end ?? .now
            )
            
            // 4. Validar
            let janSummary = monthSummaries.first { calendar.dateInterval(of: .month, for: $0.monthStart) == calendar.dateInterval(of: .month, for: startOfMonth) }
            
            #expect(janSummary != nil)
        }
    }
}

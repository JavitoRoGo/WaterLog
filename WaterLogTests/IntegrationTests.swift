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
            #expect(summaries.first?.totalMilliliters == 1250, "El resumen debe sumar correctamente las entradas de la DB")
        }

        @Test("El progreso calculado debe usar el DailyGoal persistido en lugar del defaultGoal")
        func testProgressWithPersistedGoal() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let customGoalAmount = 3000
            
            // 1. Insertar entrada y objetivo personalizado
            let entry = WaterIntakeEntry(date: today, amount: 1500)
            let goal = DailyGoal(date: today, amount: customGoalAmount)
            env.context.insert(entry)
            env.context.insert(goal)
            try env.context.save()
            
            // 2. Recuperar ambos
            let entries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            let goals = try env.context.fetch(FetchDescriptor<DailyGoal>())
            
            // 3. Ejecutar analítica
            let summaries = IntakeAnalytics.dailySummaries(
                for: entries,
                goals: goals,
                defaultGoal: 2000, // Este debería ser ignorado
                from: today,
                through: today
            )
            
            // 4. Validar que el resumen use el objetivo de la DB (3000) y no el default (2000)
            let summary = summaries.first
            #expect(summary?.dailyGoal == customGoalAmount)
            #expect(#require(summary?.progress).isApproximatelyEqual(to: 0.5, absoluteTolerance: 0.000001), "El progreso debe ser 1500/3000 = 0.5")
        }
    }

    @MainActor
    @Suite("Integración de Series Temporales")
    struct TemporalIntegration {

        @Test("Los resúmenes mensuales deben promediar correctamente sobre los días con datos persistidos")
        func testMonthlyAverageFromPersistedHistory() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            #require(calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)))
            
            // 1. Insertar datos para 3 días distintos del mes
            // Día 1: 1000ml
            env.context.insert(WaterIntakeEntry(date: startOfMonth, amount: 1000))
            // Día 2: 2000ml
            env.context.insert(WaterIntakeEntry(date: #require(calendar.date(byAdding: .day, value: 1, to: startOfMonth)), amount: 2000))
            // Día 3: 3000ml
            env.context.insert(WaterIntakeEntry(date: #require(calendar.date(byAdding: .day, value: 2, to: startOfMonth)), amount: 3000))
            // El resto del mes no tiene datos (deberían ser ignorados en el promedio según la lógica actual)
            
            try env.context.save()
            
            // 2. Recuperar
            let entries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            #require(calendar.date(byAdding: .day, value: 30, to: startOfMonth))
            
            // 3. Analizar
            let monthSummaries = IntakeAnalytics.monthSummaries(
                for: entries,
                goals: [],
                defaultGoal: 2000,
                from: startOfMonth,
                through: endOfMonth
            )
            
            // 4. Validar
            let janSummary = monthSummaries.first { calendar.dateInterval(of: .month, for: $0.monthStart) == calendar.dateInterval(of: .month, for: startOfMonth) }
            
            #expect(janSummary != nil)
            #expect(janSummary?.totalMilliliters == 6000)
            // El promedio debe ser (1000+2000+3000)/3 = 2000, ignorando los días sin registros
            #expect(janSummary?.averageDailyMilliliters == 2000)
        }
    }
}

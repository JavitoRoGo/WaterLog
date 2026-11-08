import Testing
import Foundation
import SwiftData
@testable import WaterLog

@Suite("Análisis de Ingesta")
struct IntakeAnalyticsTests {

    @Test("El progreso debe calcularse correctamente")
	@MainActor
    func testProgress() {
        #expect(abs(IntakeAnalytics.progress(for: 1000, goal: 2000) - 0.5) < 0.000001)
        #expect(abs(IntakeAnalytics.progress(for: 2500, goal: 2000) - 1.0) < 0.000001, "El progreso no debe exceder 1.0")
        #expect(abs(IntakeAnalytics.progress(for: 500, goal: 0) - 0) < 0.000001, "Si el objetivo es 0, el progreso debe ser 0 para evitar división por cero")
    }
    
    @Test("Las sumas diarias deben calcularse correctamente")
    @MainActor
    func testDailySummaries() throws {
        let env = try TestEnvironment()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        // Insertar datos de prueba
        let entry1 = WaterIntakeEntry(date: today, amount: 500)
        let entry2 = WaterIntakeEntry(date: today.addingTimeInterval(3600), amount: 750)
        env.context.insert(entry1)
        env.context.insert(entry2)
        try env.context.save()
        
        // Recuperar
        let descriptor = FetchDescriptor<WaterIntakeEntry>()
        let persistedEntries = try env.context.fetch(descriptor)
        
        // Calcular sumario
        let summaries = IntakeAnalytics.dailySummaries(
            for: persistedEntries,
            goals: [],
            defaultGoal: 2000,
            from: today,
            through: today
        )
        
        #expect(summaries.count == 1)
        #expect(summaries.first?.totalMilliliters == 1250)
    }
}

@MainActor
struct TestEnvironment {
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

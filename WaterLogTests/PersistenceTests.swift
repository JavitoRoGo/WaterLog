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
            let midDayDate = calendar.date(from: components)!
            
            let expectedDate = calendar.startOfDay(for: midDayDate)
            let goal = DailyGoal(date: midDayDate, amount: 2000)
            
            #expect(goal.date == expectedDate)
        }
    }

    // MARK: - Pruebas de Persistencia (CRUD)

    @Suite("Operaciones CRUD y Persistencia")
    struct CRUDOperations {
        
        @MainActor
        @Suite("Operaciones con Contexto")
        struct ManagedTests {
            
            @Test("Inserción: Debe permitir guardar y recuperar una entrada de agua")
            func testInsertAndFetchEntry() throws {
                let env = try TestEnvironment()
                let entry = WaterIntakeEntry(date: .now, amount: 250)
                
                env.context.insert(entry)
                try env.context.save()
                
                let descriptor = FetchDescriptor<WaterIntakeEntry>()
                let fetchedEntries = try env.context.fetch(descriptor)
                
                #expect(fetchedEntries.count == 1)
                #expect(fetchedEntries.first?.amount == 250)
            }

            @Test("Integridad/Duplicidad: No debe permitir duplicar objetivos para la misma fecha")
            func testPreventDuplicateDailyGoals() throws {
                let env = try TestEnvironment()
                let calendar = Calendar.current
                let targetDate = calendar.startOfDay(for: .now)
                
                // Primer objetivo
                let goal1 = DailyGoal(date: targetDate, amount: 2000)
                env.context.insert(goal1)
                try env.context.save()
                
                // Segundo objetivo (mismo día, diferente hora)
                var components = DateComponents()
                components.year = calendar.component(.year, from: targetDate)
                components.month = calendar.component(.month, from: targetDate)
                components.day = calendar.component(.day, from: targetDate)
                components.hour = 10
                let differentTimeSameDay = calendar.date(from: components)!
                
                let goal2 = DailyGoal(date: differentTimeSameDay, amount: 3000)
                env.context.insert(goal2)
                
                // Intentar guardar el duplicado debe ser manejado por la restricción de unicidad
                try env.context.save()
                
                let descriptor = FetchDescriptor<DailyGoal>()
                let goals = try env.context.fetch(descriptor)
                
                #expect(goals.count == 1, "No debería haber dos objetivos para el mismo día.")
            }

            @Test("Borrado: Debe eliminar correctamente un objeto del contexto")
            func testDeleteEntry() throws {
                let env = try TestEnvironment()
                let entry = WaterIntakeEntry(date: .now, amount: 500)
                env.context.insert(entry)
                try env.context.save()
                
                // Verificar existencia
                let descriptor = FetchDescriptor<WaterIntakeEntry>()
                #expect(try env.context.fetch(descriptor).count == 1)
                
                // Borrar
                env.context.delete(entry)
                try env.context.save()
                
                // Verificar ausencia
                let finalEntries = try env.context.fetch(descriptor)
                #expect(finalEntries.isEmpty)
            }
        }
    }
}

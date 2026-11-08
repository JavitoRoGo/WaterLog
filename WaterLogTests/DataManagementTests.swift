import Testing
import Foundation
import SwiftData
@testable import WaterLog

@Suite("Fase 3: Gestión de Datos (DTO & Backup)")
struct DataManagementTests {

    // MARK: - Test Environment
    
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

    // MARK: - 1. Pruebas de Serialización (Exportación)

    @MainActor
    @Suite("Serialización (Exportación)")
    struct ExportTests {
        
        @Test("Validar que los modelos se convierten correctamente a DTOs y JSON válido")
        func testExportConversionAndJSONFormat() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            
            // 1. Preparar datos de prueba
            let entry1 = WaterIntakeEntry(date: today, amount: 500)
            let entry2 = WaterIntakeEntry(date: today.addingTimeInterval(3600), amount: 750)
            env.context.insert(entry1)
            env.context.insert(entry2)
            try env.context.save()
            
            // 2. Ejecutar Exportación
            let helper = DTOHelper(entries: [entry1, entry2], modelContext: env.context)
            let exportURL = try #require(helper.generateExportURL())
            
            // 3. Verificar contenido del JSON manualmente
            let data = try Data(contentsOf: exportURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(WaterLogBackupDTO.self, from: data)
            
            // 4. Validaciones de integridad
            #expect(backup.entries.count == 2)
            #expect(backup.entries.contains { $0.amount == 500 })
            #expect(backup.entries.contains { $0.amount == 750 })
            
            // Verificar que la fecha máxima coincida (última entrada)
            let maxDateInBackup = backup.entries.map(\.date).max()
            #expect(backup.lastEntryDate == maxDateInBackup)
            
            // Limpiar
            try? FileManager.default.removeItem(at: exportURL)
        }
    }

    // MARK: - 2. Pruebas de Deserialización e Inserción (Importación)

    @MainActor
    @Suite("Deserialización e Inserción (Importación)")
    struct ImportTests {

        @Test("Caso de éxito limpio: Importar JSON en contexto vacío")
        func testCleanImport() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            
            // 1. Crear un JSON manualmente para simular un backup válido
            let entriesDTO = [
                WaterIntakeEntryDTO(date: today, amount: 1000),
                WaterIntakeEntryDTO(date: today.addingTimeInterval(86400), amount: 2000)
            ]
            let backup = WaterLogBackupDTO(entries: entriesDTO, exportDate: .now)
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("clean_import.json")
            try data.write(to: tempURL)
            
            // 2. Ejecutar Importación
            let helper = DTOHelper(entries: [], modelContext: env.context)
            let result = helper.importJSON(from: tempURL)
            
            // 3. Validar (Corregido: usando switch para evitar error de comparacion de Result)
            switch result {
            case .success:
                break // Éxito esperado
            case .failure(let error):
                Issue.record("La importación debería haber tenido éxito, pero falló con: \(error)")
            }
            
            let fetchedEntries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            #expect(fetchedEntries.count == 2)
            #expect(fetchedEntries.contains { $0.amount == 1000 })
            #expect(fetchedEntries.contains { $0.amount == 2000 })
            
            try? FileManager.default.removeItem(at: tempURL)
        }

        @Test("Caso Crítico (Cutoff): Validar borrado de historial antiguo y preservación de nuevo")
        func testImportWithCutoffLogic() throws {
            let env = try TestEnvironment()
            let calendar = Calendar.current
            
            // Usamos una fecha base fija para evitar problemas con la precisión de .now o cambios de día
            let components = DateComponents(year: 2024, month: 5, day: 10)
            let baseDate = #require(calendar.date(from: components))
            
            // Escenario Temporal:
            // - Registros antiguos (Día -2, Día -1) -> DEBEN BORRARSE
            // - Registro actual coincidente con backup (Día 0) -> SE MANTIENE/REEMPLAZA (según lógica de inserción)
            // - Registro futuro (Día +1) -> DEBE QUEDAR INTACTO
            
            let oldDate = #require(calendar.date(byAdding: .day, value: -2, to: baseDate)) 
            let currentDay = baseDate
            let futureDate = #require(calendar.date(byAdding: .day, value: 1, to: baseDate)) 
            
            env.context.insert(WaterIntakeEntry(date: oldDate, amount: 100))
            env.context.insert(WaterIntakeEntry(date: currentDay, amount: 500))
            env.context.insert(WaterIntakeEntry(date: futureDate, amount: 999))
            try env.context.save()
            
            // 1. Crear Backup que contenga datos del "Día 0" como el más reciente (cutoff)
            let backupEntries = [
                WaterIntakeEntryDTO(date: currentDay, amount: 2500), // Nuevo valor para el día actual
                WaterIntakeEntryDTO(date: currentDay.addingTimeInterval(3600), amount: 100)
            ]
            let backup = WaterLogBackupDTO(entries: backupEntries, exportDate: .now)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cutoff_import.json")
            try data.write(to: tempURL)
            
            // 2. Ejecutar Importación
            let currentEntries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            let helper = DTOHelper(entries: currentEntries, modelContext: env.context)
            let result = helper.importJSON(from: tempURL)
            
            // 3. Validar Integridad de Datos
            switch result {
            case .success:
                break
            case .failure(let error):
                Issue.record("La importación con cutoff debería haber tenido éxito, pero falló con: \(error)")
            }
            
            let finalEntries = try env.context.fetch(FetchDescriptor<WaterIntakeEntry>())
            
            // Validamos que el registro de 100ml (el antiguo) no esté en la lista de resultados.
            // Usamos una condición más robusta para evitar falsos positivos por precisión de fechas.
            let oldEntriesExist = finalEntries.contains { entry in
                entry.amount == 100 && entry.date < currentDay
            }
            #expect(oldEntriesExist == false, "Los datos antiguos (antes del cutoff) deben ser borrados")
            
            // El registro del "Día +1" debe seguir existiendo intacto
            #expect(finalEntries.contains { $0.amount == 999 }, "Los datos futuros fuera del rango de corte deben mantenerse")
            
            // Los nuevos datos deben estar presentes
            #expect(finalEntries.contains { $0.amount == 2500 })
            #expect(finalEntries.contains { $0.amount == 100 && $0.date >= currentDay }, "La entrada del backup con +1h debe existir")
            
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    // MARK: - 3. Pruebas de Robustez (Error Handling)

    @MainActor
    @Suite("Robustez (Manejo de Errores)")
    struct ErrorHandlingTests {

        @Test("Validar error con JSON malformado")
        func testMalformedJSON() throws {
            let env = try TestEnvironment()
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("malformed.json")
            let garbageData = #require("{\"invalid\": \"data\"}".data(using: .utf8))
            try garbageData.write(to: tempURL)
            
            let helper = DTOHelper(entries: [], modelContext: env.context)
            let result = helper.importJSON(from: tempURL)
            
            // Validar que el resultado sea un error (Corregido)
            if case .success = result {
                Issue.record("La importación debería haber fallado con un JSON malformado")
            }
            
            try? FileManager.default.removeItem(at: tempURL)
        }

        @Test("Validar error con campos obligatorios faltantes")
        func testMissingRequiredFields() throws {
            let env = try TestEnvironment()
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing_fields.json")
            
            // JSON sin el campo 'amount' en una de las entradas
            let partialJSON = """
            {
                "entries": [
                    {"date": "2024-01-01T10:00:00Z"}
                ],
                "exportDate": "2024-01-01T12:00:00Z",
                "lastEntryDate": "2024-01-01T10:00:00Z"
            }
            """.data(using: .utf8)
            try partialJSON.write(to: tempURL)
            
            let helper = DTOHelper(entries: [], modelContext: env.context)
            let result = helper.importJSON(from: tempURL)
            
            // Validar que el resultado sea un error (Corregido)
            if case .success = result {
                Issue.record("La importación debería haber fallado por falta de campos obligatorios")
            }
            
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
}

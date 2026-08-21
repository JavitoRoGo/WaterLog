import Testing
import Foundation
@testable import WaterLog

@Suite("Fase 4: Preferencias y Configuración (UserDefaults)")
struct SettingsManagementTests {

    // MARK: - Test Environment
    
    /// Entorno controlado para aislar las pruebas de UserDefaults del usuario real.
    final class SettingsTestEnvironment {
        let testSuiteName = "com.WaterLog.Tests.UserDefaults"
        let userDefaults: UserDefaults
        
        init() {
            // Limpiar cualquier residuo previo de tests anteriores antes de empezar
            UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
            self.userDefaults = UserDefaults(suiteName: testSuiteName)!
        }
        
        /// Elimina el dominio persistente para asegurar limpieza total después de los tests.
        func tearDown() {
            userDefaults.removePersistentDomain(forName: testSuiteName)
        }
    }

    // MARK: - 1. Pruebas de Objetivo Estándar

    @Suite("Gestión del Objetivo Diario")
	@MainActor
    struct DailyGoalTests {
        
        @Test("Validar que el cambio de objetivo estándar se guarda y recupera correctamente")
        func testStandardGoalPersistence() throws {
            let env = SettingsTestEnvironment()
            defer { env.tearDown() }
            
            let newGoal = 2500
            
            // Simular escritura (lo que haría @AppStorage en la App)
            env.userDefaults.set(newGoal, forKey: WaterLogStore.keyForStandardGoalMilliliters)
            
            // Validar lectura
            let retrievedGoal = env.userDefaults.integer(forKey: WaterLogStore.keyForStandardGoalMilliliters)
            #expect(retrievedGoal == newGoal, "El objetivo guardado debe coincidir con el recuperado.")
        }

        @Test("Validar recuperación de valores por defecto cuando el UserDefaults está vacío")
        func testDefaultGoalFallback() throws {
            let env = SettingsTestEnvironment()
            defer { env.tearDown() }
            
            // No escribimos nada en el suite
            let retrievedGoal = env.userDefaults.integer(forKey: WaterLogStore.keyForStandardGoalMilliliters)
            
            // Nota: En SwiftData/AppStorage, si la clave no existe, integer(forKey:) devuelve 0.
            // La lógica de la App (visto en SettingsView y StatisticsView) usa el valor de IntakeConstants como fallback.
            // Aquí validamos que la ausencia de valor es detectada correctamente por la infraestructura.
            #expect(retrievedGoal == 0, "Al estar vacío, el sistema debería reportar 0 para manejar el fallback a IntakeConstants.")
        }
    }

    // MARK: - 2. Pruebas de Botones de Acceso Rápido (Quick Add)

    @Suite("Configuración de Botones Quick Add")
    struct QuickAddButtonsTests {
        
        @Test("Validar persistencia de los tres volúmenes predeterminados")
        func testQuickAddButtonsPersistence() throws {
            let env = SettingsTestEnvironment()
            defer { env.tearDown() }
            
            let amounts = [300, 500, 750]
            let keys = ["buttonAmount1", "buttonAmount2", "buttonAmount3"]
            
            // Escribir los tres valores
            for (index, amount) in amounts.enumerated() {
                env.userDefaults.set(amount, forKey: keys[index])
            }
            
            // Validar lectura
            for (index, expectedAmount) in amounts.enumerated() {
                let retrieved = env.userDefaults.integer(forKey: keys[index])
                #expect(retrieved == expectedAmount, "El botón \(index + 1) no recuperó el valor correcto.")
            }
        }
    }

    // MARK: - 3. Pruebas de Robustez y Límites

    @Suite("Robustez y Casos Críticos")
	@MainActor
    struct RobustnessTests {
        
        @Test("Validar que se pueden guardar valores extremos (Edge Cases)")
        func testExtremeValues() throws {
            let env = SettingsTestEnvironment()
            defer { env.tearDown() }
            
            // Un objetivo muy alto pero válido
            let largeGoal = 10_000
            env.userDefaults.set(largeGoal, forKey: WaterLogStore.keyForStandardGoalMilliliters)
            #expect(env.userDefaults.integer(forKey: WaterLogStore.keyForStandardGoalMilliliters) == largeGoal)
            
            // Un valor de botón inusual (ej. 1ml para testing de límites bajos)
            let smallAmount = 1
            env.userDefaults.set(smallAmount, forKey: "buttonAmount1")
            #expect(env.userDefaults.integer(forKey: "buttonAmount1") == smallAmount)
        }

        @Test("Validar integridad de tipos (evitar corrupción por tipos incorrectos)")
        func testTypeIntegrity() throws {
            let env = SettingsTestEnvironment()
            defer { env.tearDown() }
            
            // Intentar guardar un String donde se espera un Int (simulando posible error de migración o corrupción)
            env.userDefaults.set("no_soy_un_int", forKey: WaterLogStore.keyForStandardGoalMilliliters)
            
            let retrieved = env.userDefaults.integer(forKey: WaterLogStore.keyForStandardGoalMilliliters)
            
            // UserDefaults.integer(forKey:) devuelve 0 si el tipo es incompatible
            #expect(retrieved == 0, "La lectura de un tipo incorrecto debe devolver 0 para permitir el fallback seguro.")
        }
    }
}

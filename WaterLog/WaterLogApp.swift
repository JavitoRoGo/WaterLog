import SwiftData
import SwiftUI

@main
struct WaterLogApp: App {
    private let modelContainer: ModelContainer

    init() {
        WaterLogStore.migrateLegacyStoreIfNeeded()

        do {
            modelContainer = try WaterLogStore.makeModelContainer()
            print("SwiftData store: \(WaterLogStore.storeURL.absoluteString)")
        } catch {
            fatalError("No se pudo crear el contenedor SwiftData: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

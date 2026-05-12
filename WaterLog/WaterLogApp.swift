import SwiftData
import SwiftUI

@main
struct WaterLogApp: App {
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([WaterIntakeEntry.self])
        let storeURL = URL.applicationSupportDirectory.appending(path: "WaterLog.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
			print("SwiftData store: \(storeURL.absoluteString)")
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

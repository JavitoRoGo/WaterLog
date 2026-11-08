import SwiftData
import SwiftUI

@main
struct WaterLogApp: App {
    private let modelContainer: ModelContainer

    init() {
        WaterLogStore.migrateLegacyStoreIfNeeded()

		modelContainer = WaterLogStore.makeModelContainer
		print("SwiftData store: \(WaterLogStore.storeURL.absoluteString)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

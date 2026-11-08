import Foundation
import SwiftData

enum WaterLogStore {
    static let appGroupIdentifier = "group.com.JRG79.WaterLog"
    static let keyForLastSuccessDate = "lastSuccessDate"
    static let keyForStandardGoalMilliliters = "standardGoalMilliliters"
    static let keyForSuccessRateAnalysisPeriod = "keyForSuccessRateAnalysisPeriod"

    private static let storeFileName = "WaterLog.store"
    private static let schema = Schema([WaterIntakeEntry.self, DailyGoal.self])
    private static let legacyStoreURL = URL.applicationSupportDirectory.appending(path: storeFileName)

    // Store URL computed after storeFileName/schema are initialized
    static var storeURL: URL {
        if let sharedContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return sharedContainerURL.appending(path: storeFileName)
        }

        return legacyStoreURL
    }

    // Shared model container created once and reused (initialized on first access)
    // Note: storeURL must be initialized before this is first accessed.
    private static let sharedModelContainer: ModelContainer = {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    // Public accessor for the shared model container (used by App and Widget)
    static var makeModelContainer: ModelContainer {
        sharedModelContainer
    }

    static func migrateLegacyStoreIfNeeded() {
        let destinationURL = storeURL
        guard destinationURL != legacyStoreURL else { return }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyStoreURL.path()),
              !fileManager.fileExists(atPath: destinationURL.path()) else {
            return
        }

        do {
            try fileManager.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let legacyDirectoryURL = legacyStoreURL.deletingLastPathComponent()
            let legacyStoreFiles = try fileManager.contentsOfDirectory(
                at: legacyDirectoryURL,
                includingPropertiesForKeys: nil
            )
            .filter { $0.lastPathComponent.hasPrefix(storeFileName) }

            for sourceURL in legacyStoreFiles {
                let destinationFileURL = destinationURL
                    .deletingLastPathComponent()
                    .appending(path: sourceURL.lastPathComponent)
                try fileManager.copyItem(at: sourceURL, to: destinationFileURL)
            }
        } catch {
            print("SwiftData store could not be migrated to App Group: \(error.localizedDescription)")
        }
    }
	
@MainActor
static func addEntry(amount: Int, date: Date = .now) {
    let modelContext = ModelContext(sharedModelContainer)
    let entry = WaterIntakeEntry(date: date, amount: amount)
    modelContext.insert(entry)
    try? modelContext.save()
}
}

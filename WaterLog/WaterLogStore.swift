import Foundation
import SwiftData

enum WaterLogStore {
    static let appGroupIdentifier = "group.com.JRG79.WaterLog"
    static let keyForLastSuccessDate = "lastSuccessDate"

    private static let storeFileName = "WaterLog.store"
    private static let schema = Schema([WaterIntakeEntry.self])
    private static let legacyStoreURL = URL.applicationSupportDirectory.appending(path: storeFileName)

    static var storeURL: URL {
        if let sharedContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return sharedContainerURL.appending(path: storeFileName)
        }

        return legacyStoreURL
    }

    static func makeModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
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
	static func addEntry(amount: Int, date: Date = .now) throws {
		let configuration = ModelConfiguration(schema: schema, url: storeURL)
		let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
		let modelContext = ModelContext(modelContainer)
		let entry = WaterIntakeEntry(date: date, amount: amount)
		modelContext.insert(entry)
		try modelContext.save()
	}
}

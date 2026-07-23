//
//  DTOs.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 22/07/2026.
//

import Foundation
import WidgetKit
import SwiftData

// MARK: - Data Transfer Objects (DTO)

/// Representación plana y Codable de WaterIntakeEntry para exportación/importación segura.
struct WaterIntakeEntryDTO: Codable {
	let date: Date
	let amount: Int
}

/// Contenedor para la colección de entradas en el JSON
struct WaterLogBackupDTO: Codable {
	let entries: [WaterIntakeEntryDTO]
	let exportDate: Date
}

struct DTOHelper {
	let entries: [WaterIntakeEntry]
	let modelContext: ModelContext
	
	// MARK: - Export Logic

	/// Genera un archivo temporal JSON con los datos actuales para que ShareLink pueda usarlo.
	func generateExportURL() -> URL? {
		let dtos = entries.map { WaterIntakeEntryDTO(date: $0.date, amount: $0.amount) }
		let backup = WaterLogBackupDTO(entries: dtos, exportDate: .now)
		
		do {
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .iso8601
			let data = try encoder.encode(backup)
			
			let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WaterLog_Backup.json")
			try data.write(to: tempURL)
			return tempURL
		} catch {
			print("Error generating export: \(error)")
			return nil
		}
	}

	// MARK: - Import Logic
	
	func importJSON(from url: URL) -> Result<Void, Error> {
		guard url.startAccessingSecurityScopedResource() else {
			return .failure(CocoaError(.fileReadNoPermission))
		}
		defer { url.stopAccessingSecurityScopedResource() }
		
		do {
			let data = try Data(contentsOf: url)
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let backup = try decoder.decode(WaterLogBackupDTO.self, from: data)
			
			// Limpieza y reemplazo
			for entry in entries {
				modelContext.delete(entry)
			}
			try modelContext.save()
			
			for dto in backup.entries {
				let newEntry = WaterIntakeEntry(date: dto.date, amount: dto.amount)
				modelContext.insert(newEntry)
			}
			
			try modelContext.save()
			WidgetCenter.shared.reloadAllTimelines()
			return .success(())
			
		} catch {
			return .failure(error)
		}
	}
}

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
	let lastEntryDate: Date?
	
	// Inicializador personalizado para que el cálculo sea transparente
	init(entries: [WaterIntakeEntryDTO], exportDate: Date) {
		self.entries = entries
		self.exportDate = exportDate
		// El cálculo se hace una sola vez al nacer el objeto
		self.lastEntryDate = entries.map(\.date).max()
	}
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
			
			// 1. Determinamos el punto de corte basado en la fecha más reciente del archivo importado
			// Usamos una pequeña tolerancia o simplemente la fecha exacta para decidir qué borrar.
			// Según tu instrucción: borramos lo anterior a lastEntryDate y mantenemos lo posterior.
			guard let cutoffDate = backup.lastEntryDate else {
				// Si el archivo no tiene entradas, no hacemos nada para evitar borrar todo por error
				return .success(())
			}

			// 2. Identificamos los registros existentes que debemos eliminar (los anteriores a la fecha del backup)
			// Nota: Usamos entries (que son las actuales en memoria/contexto) para el filtrado.
			for entry in entries where entry.date <= cutoffDate {
				modelContext.delete(entry)
			}
			
			// 3. Insertamos los nuevos registros del DTO
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

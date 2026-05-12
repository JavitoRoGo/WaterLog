import Foundation
import SwiftData
import Playgrounds

@Model
final class WaterIntakeEntry {
    #Index<WaterIntakeEntry>([\.date])

    var date: Date
    var amount: Int

    var amountMeasurement: Measurement<UnitVolume> {
        Measurement(value: Double(amount), unit: .milliliters)
    }

    init(date: Date = .now, amount: Int) {
        self.date = date
        self.amount = amount
    }

    /// Importa entradas de una ruta a fichero CSV. Cada línea debe tener formato: dd/mm/aaaa,ml
    /// - Parameters:
    ///   - filePath: Ruta local del fichero CSV.
    ///   - modelContext: Contexto de modelo SwiftData para insertar los objetos.
    /// - Returns: Número de registros insertados y número de líneas con error.
    @MainActor
    static func importFromCSV(modelContext: ModelContext) async throws -> (inserted: Int, failed: Int) {
        let filePath = "/Users/javirg/Developer/watercsv.csv"
		let url = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
		
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        dateFormatter.locale = Locale(identifier: "es_ES")

        var inserted = 0
        var failed = 0
        for line in lines {
            let parts = line.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2,
                  let date = dateFormatter.date(from: String(parts[0])),
                  let amount = Int(parts[1]) else {
                failed += 1
                continue
            }
            let entry = WaterIntakeEntry(date: date, amount: amount)
            modelContext.insert(entry)
            inserted += 1
        }
        try modelContext.save()
        return (inserted, failed)
    }
}

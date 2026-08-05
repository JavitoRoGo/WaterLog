import Foundation
import SwiftData

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
}

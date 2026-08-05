import Foundation
import SwiftData

@Model
final class DailyGoal {
	@Attribute(.unique) var date: Date // We will ensure this is always startOfDay
	var amount: Int
	
	init(date: Date, amount: Int) {
		// Normalize date to start of day to prevent duplicate entries for the same day
		self.date = Calendar.current.startOfDay(for: date)
		self.amount = amount
	}
}

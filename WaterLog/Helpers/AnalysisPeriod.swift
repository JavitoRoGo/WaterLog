import Foundation

enum AnalysisPeriod: Int, CaseIterable, Identifiable {
	case lastWeek = 7    // 7 días
	case lastMonth = 30   // 30 días
	case lastYear = 365    // 365 días
	case allTime = 0    // Todo el histórico
	
	var id: Self { self }
	
	var periodLabel: LocalizedStringResource {
		switch self {
		case .lastWeek:
			"Last 7 days"
		case .lastMonth:
			"Last 30 days"
		case .lastYear:
			"Last year"
		case .allTime:
			"All time"
		}
	}
}

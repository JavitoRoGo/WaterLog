import Foundation

enum StatisticsPeriod: CaseIterable, Identifiable {
    case sevenDays
	case oneMonth
    case oneYear
    case total

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .sevenDays:
            "7 days"
		case .oneMonth:
			"1 month"
        case .oneYear:
            "1 year"
        case .total:
            "Total"
        }
    }
}

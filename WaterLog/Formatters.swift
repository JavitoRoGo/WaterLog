import Foundation

enum WaterLogFormatters {
    static func milliliters(_ value: Int) -> String {
        value.formatted(.number.locale(IntakeConstants.spanishLocale))
    }

    static func liters(_ value: Int) -> String {
        let liters = Double(value) / 1000.0
        return liters.formatted(.number.precision(.fractionLength(0...1)).locale(IntakeConstants.spanishLocale))
    }

    static func percentage(_ value: Int) -> String {
        "\(value.formatted(.number.locale(IntakeConstants.spanishLocale))) %"
    }

    static func shortDayAndMonth(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(IntakeConstants.spanishLocale))
            .replacing(".", with: "")
    }

    static func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).locale(IntakeConstants.spanishLocale))
    }

    static func month(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).locale(IntakeConstants.spanishLocale))
    }

    static func year(_ date: Date) -> String {
        date.formatted(.dateTime.year().locale(IntakeConstants.spanishLocale))
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(IntakeConstants.spanishLocale))
    }
}

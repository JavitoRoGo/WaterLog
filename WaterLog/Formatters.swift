import Foundation

enum WaterLogFormatters {
    static func milliliters(_ value: Int) -> String {
        value.formatted(.number.locale(IntakeConstants.appLocale))
    }

    static func liters(_ value: Int) -> String {
        let liters = Double(value) / 1000.0
        return liters.formatted(.number.precision(.fractionLength(0...1)).locale(IntakeConstants.appLocale))
    }

    static func percentage(_ value: Int) -> String {
        "\(value.formatted(.number.locale(IntakeConstants.appLocale))) %"
    }

    static func shortDayAndMonth(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(IntakeConstants.appLocale))
            .replacing(".", with: "")
    }

    static func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).locale(IntakeConstants.appLocale))
    }

    static func month(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).locale(IntakeConstants.appLocale))
    }

    static func year(_ date: Date) -> String {
        date.formatted(.dateTime.year().locale(IntakeConstants.appLocale))
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(IntakeConstants.appLocale))
    }
}

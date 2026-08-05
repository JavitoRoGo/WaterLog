import Foundation

enum WaterLogFormatters {
    static func volumeFromMilliliters(_ value: Int) -> String {
        volumeFromMilliliters(Double(value))
    }

    static func volumeFromMilliliters(_ value: Double) -> String {
        volumeMeasurement(value).converted(to: preferredSmallVolumeUnit()).formatted(volumeFormatStyle)
    }

    static func largeVolumeFromMilliliters(_ value: Int) -> String {
        volumeMeasurement(Double(value)).converted(to: preferredLargeVolumeUnit()).formatted(volumeFormatStyle)
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

    private static var volumeFormatStyle: Measurement<UnitVolume>.FormatStyle {
        .measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(0...2))
        )
        .locale(IntakeConstants.appLocale)
    }

    private static func volumeMeasurement(_ milliliters: Double) -> Measurement<UnitVolume> {
        Measurement(value: milliliters, unit: .milliliters)
    }

    private static func preferredSmallVolumeUnit(locale: Locale = IntakeConstants.appLocale) -> UnitVolume {
        switch locale.measurementSystem {
        case .us:
            .fluidOunces
        case .uk:
            .imperialFluidOunces
        default:
            .milliliters
        }
    }

    private static func preferredLargeVolumeUnit(locale: Locale = IntakeConstants.appLocale) -> UnitVolume {
        switch locale.measurementSystem {
        case .us:
            .gallons
        case .uk:
            .imperialGallons
        default:
            .liters
        }
    }
}

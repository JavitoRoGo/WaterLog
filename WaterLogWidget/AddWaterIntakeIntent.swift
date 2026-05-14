import AppIntents
import WidgetKit

struct AddWaterIntakeIntent: AppIntent {
    static var title: LocalizedStringResource { "Añadir agua" }
    static var description: IntentDescription { IntentDescription("Registra una nueva toma de agua.") }
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Cantidad")
    var amount: Int

    init() {
        amount = 250
    }

    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        try await WaterLogStore.addEntry(amount: amount)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

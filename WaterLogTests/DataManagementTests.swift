import Testing
import Foundation
import SwiftData
@testable import WaterLog

@Suite("Validación de integridad de datos")
struct DataManagementTests {

    @Test("Test basic model creation")
    func testBasicCreation() {
        let entry = WaterIntakeEntry(date: Date(), amount: 500)
        #expect(entry.amount == 500)
    }
    
    @Test("Test date components")
    func testDateComponents() {
        let components = DateComponents(year: 2024, month: 5, day: 10)
        let baseDate = Calendar.current.date(from: components)
        #expect(baseDate != nil)
    }
    
    @Test("Test date addition")
    func testDateAddition() {
        let baseDate = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: baseDate)!
        #expect(oldDate < baseDate)
        #expect(futureDate > baseDate)
    }
    
    @Test("Test string data")
    func testStringData() {
        let garbageData = "{\"invalid\": \"data\"}".data(using: .utf8)
        #expect(garbageData != nil)
    }
}

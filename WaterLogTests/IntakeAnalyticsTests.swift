import Testing
import Foundation
@testable import WaterLog

@Suite("Pruebas de la lógica analítica en IntakeAnalytics")
struct IntakeAnalyticsTests {
	
	// MARK: - Helpers para generación de datos (Mocks)
	
	/// Genera una fecha a una hora específica para evitar problemas con zonas horarias al comparar días.
	private func createDate(year: Int, month: Int, day: Int) -> Date {
		let calendar = Calendar.current
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		components.hour = 12 // Mediodía para evitar ambigüedades de fin de día
		return calendar.date(from: components)!
	}
	
	/// Crea un array de entradas simuladas para un periodo determinado.
	private func makeEntries(count: Int, amountPerEntry: Int, startDate: Date) -> [WaterIntakeEntry] {
		let calendar = Calendar.current
		return (0..<count).map { i in
			let date = calendar.date(byAdding: .day, value: -i, to: startDate)!
			return WaterIntakeEntry(date: date, amount: amountPerEntry)
		}
	}
	
	// MARK: - Basic Calculations Suite
	
	@Suite("Cálculos básicos (Progreso y Porcentaje)")
	@MainActor // Añadido para acceder a métodos de IntakeAnalytics que lo requieran
	struct BasicCalculations {
		
		@Test("El progreso debe calcularse correctamente")
		func testProgress() {
			#expect(IntakeAnalytics.progress(for: 1000, goal: 2000) == 0.5)
			#expect(IntakeAnalytics.progress(for: 2500, goal: 2000) == 1.0, "El progreso no debe exceder 1.0")
			#expect(IntakeAnalytics.progress(for: 500, goal: 0) == 0, "Si el objetivo es 0, el progreso debe ser 0 para evitar división por cero")
		}
		
		@Test("El porcentaje debe calcularse y redondear correctamente")
		func testPercentage() {
			#expect(IntakeAnalytics.percentage(for: 1500, goal: 2000) == 75)
			#expect(IntakeAnalytics.percentage(for: 666, goal: 1000) == 67, "Debe redondear al entero más cercano")
			#expect(IntakeAnalytics.percentage(for: 2500, goal: 2000) == 125)
			#expect(IntakeAnalytics.percentage(for: 500, goal: 0) == 0)
		}
	}
	
	// MARK: - Temporal Aggregation Suite
	
	@Suite("Agregación temporal (Resúmenes diarios, mensuales y anuales)")
	@MainActor
	struct TemporalAggregation {
		
		@Test("Daily summaries debe respetar objetivos específicos y el defaultGoal")
		func testDailySummaries() {
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: .now)
			let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
			
			let entries = [
				WaterIntakeEntry(date: today, amount: 1000),
				WaterIntakeEntry(date: yesterday, amount: 500)
			]
			
			let specificGoal = DailyGoal(date: yesterday, amount: 800)
			let defaultGoal = 2000
			
			let summaries = IntakeAnalytics.dailySummaries(
				for: entries,
				goals: [specificGoal],
				defaultGoal: defaultGoal,
				from: yesterday,
				through: today
			)
			
			#expect(summaries.count == 2)
			
			let summaryYesterday = summaries.first { $0.date == calendar.startOfDay(for: yesterday) }
			#expect(summaryYesterday?.totalMilliliters == 500)
			#expect(summaryYesterday?.dailyGoal == 800)
			
			let summaryToday = summaries.first { $0.date == calendar.startOfDay(for: today) }
			#expect(summaryToday?.totalMilliliters == 1000)
			#expect(summaryToday?.dailyGoal == 2000)
		}
		
		@Test("Month summaries debe promediar solo sobre días registrados")
		func testMonthSummaries() {
			let calendar = Calendar.current
			let startOfMonth = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
			let endOfMonth = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
			
			let entries = [
				WaterIntakeEntry(date: startOfMonth, amount: 1000),
				WaterIntakeEntry(date: calendar.date(byAdding: .day, value: 1, to: startOfMonth)!, amount: 2000),
				WaterIntakeEntry(date: calendar.date(byAdding: .day, value: 2, to: startOfMonth)!, amount: 3000)
			]
			
			let summaries = IntakeAnalytics.monthSummaries(
				for: entries,
				goals: [],
				defaultGoal: 2000,
				from: startOfMonth,
				through: endOfMonth
			)
			
			let janSummary = summaries.first { calendar.dateInterval(of: .month, for: $0.monthStart) == calendar.dateInterval(of: .month, for: startOfMonth) }
			
			#expect(janSummary != nil)
			#expect(janSummary?.totalMilliliters == 6000)
			#expect(janSummary?.averageDailyMilliliters == 2000)
		}
	}
	
	// MARK: - Insight Algorithms Suite
	
	@Suite("Algoritmos de Insights y Predicción")
	@MainActor
	struct InsightAlgorithms {
		
		@Test("Consumption trend detecta mejoras y descensos")
		func testTrend() {
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: .now)
			
			var summaries: [DailyIntakeSummary] = []
			for i in 0..<30 {
				let date = calendar.date(byAdding: .day, value: -i, to: today)!
				summaries.append(DailyIntakeSummary(date: date, totalMilliliters: 1000, dailyGoal: 2000))
			}
			for i in 0..<7 {
				let date = calendar.date(byAdding: .day, value: -i, to: today)!
				if let index = summaries.firstIndex(where: { $0.date == date }) {
					summaries[index] = DailyIntakeSummary(date: date, totalMilliliters: 3000, dailyGoal: 2000)
				}
			}
			
			let trendImproving = IntakeAnalytics.calculateConsumptionTrend(from: summaries)
			#expect(trendImproving.isImproving == true)
			
			let emptyTrend = IntakeAnalytics.calculateConsumptionTrend(from: [])
			#expect(emptyTrend.shortTermAverage == 0)
		}
		
		@Test("Stability detecta patrones consistentes vs erráticos")
		func testStability() {
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: .now)
			
			var stableSummaries: [DailyIntakeSummary] = []
			for i in 1...30 {
				let date = calendar.date(byAdding: .day, value: -i, to: today)!
				stableSummaries.append(DailyIntakeSummary(date: date, totalMilliliters: 2000, dailyGoal: 2000))
			}
			
			let stableResult = IntakeAnalytics.calculateStability(from: stableSummaries, daysToAnalyze: .lastMonth)
			#expect(stableResult.isStable == true)
			
			var erraticSummaries: [DailyIntakeSummary] = []
			for i in 1...30 {
				let date = calendar.date(byAdding: .day, value: -i, to: today)!
				let amount = (i % 2 == 0) ? 4000 : 0
				erraticSummaries.append(DailyIntakeSummary(date: date, totalMilliliters: amount, dailyGoal: 2000))
			}
			
			let erraticResult = IntakeAnalytics.calculateStability(from: erraticSummaries, daysToAnalyze: .lastMonth)
			#expect(erraticResult.isStable == false)
		}
		
		@Test("Risk prediction identifica riesgos de fatiga y abandono")
		func testRiskPrediction() {
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: .now)
			
			var fatigueSummaries: [DailyIntakeSummary] = []
			for i in 0..<30 {
				let date = calendar.date(byAdding: .day, value: -i, to: today)!
				if i < 6 {
					fatigueSummaries.append(DailyIntakeSummary(date: date, totalMilliliters: 2000, dailyGoal: 2000))
				} else {
					// Subimos de 500 a 1200 para que el éxito sea mayor al 50%
					fatigueSummaries.append(DailyIntakeSummary(date: date, totalMilliliters: 1200, dailyGoal: 2000))
				}
			}
			
			let fatigueRisk = IntakeAnalytics.calculateRiskPrediction(from: fatigueSummaries, daysToAnalyze: .lastMonth)
			#expect(fatigueRisk.riskLevel == .high)
			
			let abandonmentSummaries = (0..<30).map { i in
				DailyIntakeSummary(date: calendar.date(byAdding: .day, value: -i, to: today)!, totalMilliliters: 200, dailyGoal: 2000)
			}
			let abandonmentRisk = IntakeAnalytics.calculateRiskPrediction(from: abandonmentSummaries, daysToAnalyze: .lastMonth)
			#expect(abandonmentRisk.riskLevel == .high)
		}
	}
}

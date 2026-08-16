//
//  CoachAnalytics.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 09/08/2026.
//

import Foundation

enum CoachAnalytics {
	/// Genera un contexto semántico completo diseñado para alimentar un LLM local.
	/// Este método actúa como un orquestador de todos los cálculos de la app.
	static func generateCoachingContext(
		from summaries: [DailyIntakeSummary],
		daysToAnalyze: AnalysisPeriod = .lastMonth
	) -> CoachingContext {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		// 1. Ejecutar todos los motores de cálculo existentes (Fusión de sensores)
		let trend = IntakeAnalytics.calculateConsumptionTrend(from: summaries)
		let stability = IntakeAnalytics.calculateStability(from: summaries, daysToAnalyze: daysToAnalyze)
		let success = IntakeAnalytics.calculateSuccessRate(from: summaries, daysToAnalyze: daysToAnalyze)
		let risk = IntakeAnalytics.calculateRiskPrediction(from: summaries, daysToAnalyze: daysToAnalyze)
		let evolution = IntakeAnalytics.calculateWeeklyEvolution(from: summaries)
		
		// 2. Calcular la racha actual (usando tu lógica de Streaks o una simplificada aquí)
		// Para consistencia con el resto de la app, idealmente usaríamos Streaks.calculateStreaks
		let currentStreak = Streaks.calculateStreaks(from: summaries).currentStreak
		
		// 3. Determinar la dirección de la tendencia para el LLM
		let trendDirection: CoachingContext.TrendDirection = {
			if trend.shortTermAverage > trend.longTermAverage { return .increasing }
			if trend.shortTermAverage < trend.longTermAverage && trend.shortTermAverage > 0 { return .decreasing }
			return .stable
		}()
		
		// 4. Determinar el tono (MotivationTag) basado en la combinación de factores
		let motivationTag: CoachingContext.MotivationTag = {
			// PRIMERO: Verificar si tenemos datos suficientes para ser inteligentes
			if summaries.count < 3 { return .neutral }
			
			// Si hay datos, procedemos con la lógica
			if risk.riskLevel == .high { return .urgent }
			if success.rate > 0.8 && currentStreak >= 5 { return .celebratory }
			if trendDirection == .decreasing || stability.isStable == false { return .encouraging }
			return .neutral
		}()
		
		// 5. En los patrones, marcar explícitamente si estamos en fase de aprendizaje
		let patterns = CoachingContext.DetectedPatterns(
			isImproving: summaries.count >= 3 && trend.isImproving,
			isStable: summaries.count >= 3 && stability.isStable,
			hasHighVolatility: summaries.count >= 3 && !stability.isStable && stability.stabilityScore < 0.5
		)
		
		// 6. Construir el objeto final
		return CoachingContext(
			summary: .init(
				overallRiskLevel: risk.riskLevel,
				primaryMotivationTag: motivationTag
			),
			metrics: .init(
				currentStreak: currentStreak,
				successRate: success.rate,
				stabilityScore: stability.stabilityScore,
				consumptionTrend: trendDirection,
				weeklyEvolutionChange: evolution.percentageChange
			),
			patterns: patterns,
			timestamp: today
		)
	}
}

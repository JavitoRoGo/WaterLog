//
//  FMCoachManager.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 11/08/2026.
//

import SwiftUI
import FoundationModels

@Observable
final class FMCoachService {
    let context: CoachingContext
    var session: LanguageModelSession = .init()
    var coachResponse: [CoachResponse].PartiallyGenerated = []
    var errorString: String?
    
    init(context: CoachingContext) {
        self.context = context
    }
    
    func streamAdvice() {
        // 1. Limpieza inicial en el hilo principal
        coachResponse.removeAll()
        errorString = nil
        
        let systemPrompt = """
        You are an expert Health & Hydration Coach. Your goal is to analyze user data and provide short, empathetic, and highly motivating guidance.

        TONE GUIDELINES:
        Your tone must strictly follow the provided 'primaryMotivationTag':
        - celebratory: Enthusiastic, rewarding, and joyful. Use exclamation marks! Celebrate streaks and successes.
        - encouraging: Calm, supportive, and steady. Focus on gradual progress and gentle motivation.
        - urgent: Direct, alert, and high-energy. Emphasize the importance of immediate action to correct trends or risks.
        - neutral: Professional, objective, and informative. Provide facts without excessive emotion.

        CONSTRAINTS:
        - DO NOT invent numerical data. Use only the provided context.
        - Be concise. The 'adviceMessage' should be maximum 3 sentences.
        - Always respond in valid JSON format matching the CoachResponse schema.
        - Ensure the 'actionableStep' is a very short, direct command (e.g., "Drink a glass now", "Keep it up!").
        """
        
		session = LanguageModelSession(instructions: systemPrompt)
		let contextJSON = try? JSONEncoder().encode(context)
		let contextString = contextJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let prompt = """
  USER DATA CONTEXT (JSON):
  \(contextString)

  TASK: Analyze this hydration data and provide only one personalized coaching message and one actionable step.
  """
		let stream = session.streamResponse(to: prompt, generating: [CoachResponse].self)

        Task {
            do {
                for try await chunk in stream {
                    withAnimation {
						coachResponse = chunk.content
                    }
                }
            } catch {
				handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        if let genError = error as? LanguageModelSession.GenerationError {
            switch genError {
			case .guardrailViolation(let context):
				errorString = "Guardrail violation: \(context.debugDescription)"
			case .decodingFailure(let context):
				errorString = "Decoding failure: \(context.debugDescription)"
			case .rateLimited(let context):
				errorString = "Rate limit exceeded: \(context.debugDescription)"
			default:
				errorString = "Other error: \(error.localizedDescription)"
			}
			
			if let failureReason = genError.failureReason {
				errorString! += "\nFailure reason: \(failureReason)"
			}
			if let recoverySuggestion = genError.recoverySuggestion {
				errorString! += "\nRecovery suggestion: \(recoverySuggestion)"
			}
        } else {
            errorString = "Unexpected error: \(error.localizedDescription)"
        }
    }
}

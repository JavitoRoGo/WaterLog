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
	
	
	/// Genera un consejo utilizando streaming para una experiencia fluida.
	/// - Parameter context: El contexto semántico generado por IntakeAnalytics.
	/// - Returns: Un stream de strings que representan el mensaje del coach.
	func streamAdvice() {
		// 1. Construir el System Prompt con instrucciones de identidad y formato
		let systemPrompt = """
   Eres un Coach de Salud experto, empático y altamente motivador especializado en hábitos de hidratación.
   Tu objetivo es analizar los datos del usuario y proporcionar un consejo corto, directo y humano.
   
   REGLAS CRÍTICAS:
   - NO inventes datos numéricos. Usa solo la información proporcionada.
   - Tu tono debe coincidir con la etiqueta de motivación: \(context.summary.primaryMotivationTag.rawValue).
   - Sé breve (máximo 3 frases).
   - Si el usuario está en una racha, celébralo. Si su estabilidad es baja, sé alentador pero firme.
   - Responde siempre siguiendo el formato JSON solicitado para la estructura CoachResponse.
   
   CONTEXTO DEL USUARIO (JSON):
   \(String(data: try! JSONEncoder().encode(context), encoding: .utf8) ?? "")
   """
		coachResponse.removeAll()
		Task {
			do {
				// 2. Realizar la llamada al modelo con streaming de la respuesta estructurada
				// Usamos el método que permite iterar sobre los fragmentos de la respuesta generada.
				session = LanguageModelSession(instructions: systemPrompt)
				let prompt = ""
				let stream = session.streamResponse(to: prompt, generating: [CoachResponse].self)
				
				// Nota: Al usar Generable con streaming, el framework gestiona la reconstrucción
				// de los fragmentos para que coincidan con el esquema CoachResponse.
				for try await chunk in stream {
					withAnimation {
						coachResponse = chunk.content
					}
				}
			} catch let error as LanguageModelSession.GenerationError {
				switch error {
				case .guardrailViolation(let context):
					errorString = "Guardrail violation: \(context.debugDescription)"
				case .decodingFailure(let context):
					errorString = "Decoding failure: \(context.debugDescription)"
				case .rateLimited(let context):
					errorString = "Rate limit exceeded: \(context.debugDescription)"
				default:
					errorString = "Other error: \(error.localizedDescription)"
				}
				
				if let failureReason = error.failureReason {
					errorString! += "\nFailure reason: \(failureReason)"
				}
				if let recoverySuggestion = error.recoverySuggestion {
					errorString! += "\nRecovery suggestion: \(recoverySuggestion)"
				}
			} catch {
				errorString = "Unexpected error: \(error.localizedDescription)"
			}
		}
	}
}

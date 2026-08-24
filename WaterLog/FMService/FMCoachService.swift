//
//  FMCoachService.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 11/08/2026.
//

import SwiftUI
import FoundationModels

@Observable
@MainActor
final class FMCoachService {
    let context: CoachingContext
    var session: LanguageModelSession?
    var sessionForChat: LanguageModelSession
    var coachResponse: [CoachResponse].PartiallyGenerated = []
    var errorString: String?
	
	private let systemPromptForChat = """
  You are the WaterLog AI Coach, a specialized assistant for hydration and water-related health.

  ### YOUR DOMAINS OF EXPERTISE ###
  You should only provide information and engage in conversations regarding:
  - Hydration strategies and water intake goals.
  - The physiological benefits of drinking water.
  - Electrolytes (sodium, potassium, magnesium) and their role in hydration.
  - Tips for maintaining consistent water consumption habits.
  
  ### KNOWLEDGE LIMITATION:
  - You do not have information about cooking, coding, sports, politics, or general culture. 
  - If a user asks a question that requires knowledge outside of water and hydration, you must act as if you simply do not know the answer due to your specialized programming.

  ### RESPONSE PROTOCOL:
  1. EVALUATE: Is the user asking about hydration, electrolytes, or water intake?
  2. IF YES: Provide a helpful, concise, and friendly response in the user's language. Use emojis (💧, 🌊).
  3. IF NO: Respond with: "I specialize exclusively in hydration coaching and don't have information on that topic. How can I help you with your water intake today?" (Translate this exact sentiment to the user's language).

  ### CONVERSATION BOUNDARIES ###
  - If a user's question falls within the domains above, provide helpful, encouraging, and scientifically accurate advice.
  - If a user asks about topics outside these domains (e.g., general knowledge, technology, cooking, sports, or other health areas like nutrition/dieting that don't directly involve water), politely steer the conversation back by stating your specialization. 
    *Example: "I'm here to help you with your hydration! I can't assist with [topic], but I can tell you how staying hydrated helps with your energy levels."*

  ### RULES ###
  - Never attempt to answer a question outside of your specialization, even if you think you know the answer.
  - ALWAYS USE THE SAME LANGUAGE AS THE USER IN YOUR ANSWERS.
  - Keep responses concise and friendly.
  - Use emojis (💧, 🌊) occasionally to maintain a coach persona.
  """
	
	var isResponding: Bool {
		session?.isResponding ?? false
	}
	
	/// Referencia al Task en curso, para poder cancelarlo si se lanza una nueva petición
	/// o si el servicio se destruye antes de que termine.
	private var streamingTask: Task<Void, Never>?
	
	init(context: CoachingContext) {
		self.context = context
		self.sessionForChat = LanguageModelSession(instructions: systemPromptForChat)
	}
	
	isolated deinit {
		streamingTask?.cancel()
	}
    
	func streamAdvice() {
		streamingTask?.cancel()
		
		let userLanguage = IntakeConstants.appLocale.identifier
		
		// 1. Limpieza inicial en el hilo principal
		coachResponse.removeAll()
		errorString = nil
		
		let contextString: String
		do {
			let contextData = try JSONEncoder().encode(context)
			guard let encoded = String(data: contextData, encoding: .utf8) else {
				errorString = "Could not convert the encoded context to text."
				return
			}
			contextString = encoded
		} catch {
			errorString = "Could not encode the hydration context: \(error.localizedDescription)"
			return
		}
		
		let systemPrompt = """
		You are an expert Health & Hydration Coach. Your goal is to analyze user data and provide short, empathetic, and highly motivating guidance.
		
		### MANDATORY LANGUAGE RULE ###
		- YOU MUST RESPOND EXCLUSIVELY IN THE FOLLOWING LANGUAGE: \(userLanguage).
		###############################
		
		TONE GUIDELINES:
		Your tone must strictly follow the provided 'primaryMotivationTag':
		- celebratory: Enthusiastic, rewarding, and joyful. Use exclamation marks! Celebrate streaks and successes.
		- encouraging: Calm, supportive, and steady. Focus on gradual progress and gentle motivation.
		- urgent: Direct, alert, and high-energy. Emphasize the importance of immediate action to correct trends or risks.
		- neutral: Professional, objective, and informative. Provide facts without excessive emotion.
		
		CONSTRAINTS:
		- DO NOT invent numerical data. Use only the provided context.
		- Be concise. The 'adviceMessage' should be maximum 3 sentences.
		- Ensure the 'actionableStep' is a very short, direct command (e.g., "Drink a glass now", "Keep it up!").
		"""
		
		let activeSession = LanguageModelSession(instructions: systemPrompt)
		session = activeSession
		
		let prompt = """
  USER DATA CONTEXT (JSON):
  \(contextString)
  
  TASK: Analyze this hydration data and provide a personalized coaching message and an actionable step.
  REMINDER: The response MUST be in \(userLanguage).
  """
		let stream = activeSession.streamResponse(to: prompt, generating: [CoachResponse].self)
		
		streamingTask = Task {
			do {
				for try await chunk in stream {
					// Al estar la clase completa aislada a @MainActor, esta asignación
					// ya se ejecuta siempre en el hilo principal, sin necesidad de
					// saltos explícitos de actor.
					withAnimation {
						coachResponse = chunk.content
					}
				}
			} catch is CancellationError {
				// Cancelación esperada (nueva petición o servicio destruido):
				// no es un error de cara al usuario, no tocamos errorString.
			} catch {
				handleError(error)
			}
			
			streamingTask = nil
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
	
	/// Envía un mensaje al chat y gestiona la respuesta del modelo
	func sendMessage(_ text: String) {
		streamingTask?.cancel()
		errorString = nil

		let stream = sessionForChat.streamResponse(to: text)

		Task {
			do {
				for try await _ in stream {
					
				}
			} catch is CancellationError {
				// Cancelación esperada
			} catch {
				handleError(error)
			}
		}
	}
	
	func newChat() {
		sessionForChat = LanguageModelSession(instructions: systemPromptForChat)
	}
}

//
//  PromptValidation.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 24/08/2026.
//


import Foundation
import FoundationModels

/// Define los errores posibles en el proceso de validación temática.
enum PromptValidationError: Error {
	case topicNotAllowed(detectedTopics: [String])
	case validationServiceUnavailable
}

/// Actor encargado de la validación semántica mediante Content Tagging.
actor PromptValidator {
	private let allowedTags: Set<String>
	private let taggingModel = SystemLanguageModel(useCase: .contentTagging)

	init(allowedTags: Set<String>) {
		self.allowedTags = allowedTags
	}

	/// Valida si el prompt del usuario pertenece a la temática permitida.
	func validate(_ prompt: String) async throws -> Bool {
		try await performValidation(prompt)
	}

	private func performValidation(_ prompt: String) async throws -> Bool {
		async let tagsResponse = LanguageModelSession(model: taggingModel, instructions: """
			Identify at least the 5 most significant topics in this text. 
			Return ONLY the words as a comma-separated list.
			""").respond(to: prompt)
		
		let response = try await tagsResponse
		let rawTags = response.content
		print("Raw tags: \(rawTags)")

		let englishTags = try await translateTags(rawTags)
		print("Translated tags: \(englishTags)")

		let detectedTags = cleanAndSplit(englishTags)
		print("Detected tags set: \(detectedTags)")

		let intersection = detectedTags.intersection(allowedTags)

		if !intersection.isEmpty {
			print("✅ Intersection successful")
			return true
		} else {
			print("❌ Intersection failed")
			throw PromptValidationError.topicNotAllowed(detectedTopics: [rawTags])
		}
	}

	private func translateTags(_ tags: String) async throws -> String {
		let session = LanguageModelSession(instructions: """
			Translate the following comma-separated list of words into English.
			Return ONLY the translated words, separated by commas. No extra text.
			""")
		return try await session.respond(to: tags).content
	}

	private func cleanAndSplit(_ input: String) -> Set<String> {
		let components = input.lowercased()
			.components(separatedBy: CharacterSet(charactersIn: ", \n[]{}()\"'"))
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
		return Set(components)
	}
}

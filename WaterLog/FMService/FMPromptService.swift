//
//  FMPromptService.swift
//  WaterLog
//
//  Created by Javier Rodríguez Gómez on 25/08/2026.
//

import Foundation
import FoundationModels

final class FMPromptService {
	private let validator: PromptValidator
	private let allowedTags: Set<String> = [
		"greet",
		"greeting",
		"water",
		"hydration",
		"drinking",
		"fluid intake",
		"hydration levels",
		"thirst",
		"electrolytes",
		"sodium",
		"potassium",
		"magnesium",
		"kidney health",
		"metabolism",
		"dehydration",
		"symptoms",
		"daily goals",
		"fluid balance",
		"water habits",
		"drinking habits",
		"hydration tracking",
		"health",
		"wellness",
		"language",
		"information",
		"assistance",
		"tip",
		"advice",
		"nutrition"
	]
	
	init() {
		self.validator = PromptValidator(allowedTags: allowedTags)
	}
	
	func processUserIntent(_ userInput: String) async throws -> Bool {
		try await validator.validate(userInput)
	}
}
